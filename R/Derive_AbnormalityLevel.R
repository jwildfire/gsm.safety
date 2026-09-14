#' Grade a result against the FDA abnormality level criteria
#'
#' Adds the level 1, 2 or 3 abnormality grade from Appendix Tables 56
#' (chemistry) and 57 (hematology) of the FDA Standard Safety Tables and
#' Figures Integrated Guide v2.0, the criteria the guide's "analyte values
#' exceeding specified levels" tables count on (section 2.4.3). The levels are
#' cumulative, so the grade is the highest level the result meets in the
#' row's direction with the row's operator, `0` when the parameter is graded
#' and the result meets none, and `NA` when the record cannot be graded.
#' Requirement `FDA-RULE-002`; the sex-qualified rows are `FDA-RULE-016`.
#'
#' What is graded, and what is left `NA`:
#'
#' - `uln_multiple` rows (the liver panel, CPK, amylase, lipase, PT, PTT) are
#'   graded on the result divided by its own ULN, as [Derive_ULNMultiple()]
#'   forms it, whatever unit the data carry.
#' - `absolute` rows are graded only when the record's unit matches the
#'   criteria's unit. The guide prints US-conventional units; a result in
#'   another unit is left `NA` and named in a message rather than compared on
#'   the wrong scale. Spellings of the same unit are folded (`mEq/L` and
#'   `mmol/L` for the monovalent electrolytes, `GI/L` and `x 10^9 cells/L`),
#'   but nothing is converted.
#' - Rows with a sex qualifier (HDL; hemoglobin, low) are applied only when
#'   `strSexCol` names a column, to records whose sex matches.
#' - Rows whose basis is a change or multiple of baseline (creatinine, eGFR,
#'   hemoglobin change) and the fasting or random glucose rows need columns
#'   this function does not take; they are left `NA` and reported.
#' - A test that `lParameterValues` does not map is left `NA` silently.
#'
#' Nothing is dropped or aggregated: the input frame comes back with three
#' columns added, in its original row order. Where an established grading
#' system applies (DAIDS, CTCAE) the guide allows it in place of Tables 56 and
#' 57 (`FDA-RULE-003`); pass it as `dfCriteria` in the same shape.
#'
#' @param dfResults `data.frame` Long-format results, one row per participant
#'   per test per visit, in the shape of `ExampleData("adbds")`.
#' @param dfCriteria `data.frame` The criteria, in the shape of
#'   [FDA_AbnormalityLevels] (at least `Parameter`, `Direction`, `Qualifier`,
#'   `Unit`, `Basis`, `Operator`, `Level1`, `Level2`, `Level3`). Default:
#'   `FDA_AbnormalityLevels`.
#' @param strTestCol `character` Column holding the test name. Default: `"TEST"`.
#' @param strValueCol `character` Numeric result column. Default: `"STRESN"`.
#' @param strULNCol `character` Upper-limit-of-normal column. Default: `"STNRHI"`.
#' @param strUnitCol `character` Unit column. Default: `"STRESU"`.
#' @param strSexCol `character` Sex column (`M`/`F` or `Male`/`Female`, any
#'   case), used for the sex-qualified rows. Default: `NULL`, which skips them.
#' @param lParameterValues Named `list` mapping each criteria `Parameter` to
#'   the test name(s) the data use for it. Default: the names
#'   `ExampleData("adbds")` uses.
#' @param strOutCol `character` Name of the grade column. Default:
#'   `"AbnormalityLevel"`; the direction and the criterion met are added as
#'   `<strOutCol>` with `Level` replaced by `Direction` and `Criterion`. None
#'   of the three may already be a column of `dfResults`: the function
#'   appends, it never overwrites.
#'
#' @return `dfResults` with three columns appended: the grade (`integer`
#'   0 to 3, or `NA`), the direction of the row that graded it (`"low"`,
#'   `"high"`, `"increase"`, `"decrease"`, or `NA`), and the criterion text as
#'   printed in the guide (for example `">5.5"`), `NA` where no level was met.
#'
#' @examples
#' dfLabs <- ExampleData("adbds")
#' dfLabs <- Derive_AbnormalityLevel(dfLabs)
#' dfGraded <- dfLabs[!is.na(dfLabs$AbnormalityLevel) & dfLabs$AbnormalityLevel > 0, ]
#' table(dfGraded$TEST, dfGraded$AbnormalityLevel)
#'
#' @seealso [FDA_AbnormalityLevels] for the criteria and their transcription
#'   notes; [Derive_ULNMultiple()] for the scale the ULN-multiple rows use.
#' @family FDA derivations
#' @export
Derive_AbnormalityLevel <- function(
    dfResults,
    dfCriteria = gsm.safety::FDA_AbnormalityLevels,
    strTestCol = "TEST",
    strValueCol = "STRESN",
    strULNCol = "STNRHI",
    strUnitCol = "STRESU",
    strSexCol = NULL,
    lParameterValues = DefaultAbnormalityParameters(),
    strOutCol = "AbnormalityLevel") {
  RequireResultColumns(dfResults, c(strTestCol, strValueCol, strULNCol, strUnitCol))
  RequireOutColToken(strOutCol, "Level")
  strDirectionCol <- sub("Level", "Direction", strOutCol)
  strCriterionCol <- sub("Level", "Criterion", strOutCol)
  RequireNewColumns(dfResults, c(strOutCol, strDirectionCol, strCriterionCol))
  if (!is.null(strSexCol)) {
    RequireResultColumns(dfResults, strSexCol)
  }
  RequireResultColumns(
    dfCriteria,
    c("Parameter", "Direction", "Qualifier", "Unit", "Basis", "Operator", "Level1", "Level2", "Level3"),
    strName = "dfCriteria"
  )

  nRows <- nrow(dfResults)
  chrParameter <- ResolveParameters(dfResults[[strTestCol]], lParameterValues)
  nValue <- suppressWarnings(as.numeric(dfResults[[strValueCol]]))
  nMultiple <- ULNMultiple(nValue, dfResults[[strULNCol]])
  chrUnit <- NormaliseUnit(dfResults[[strUnitCol]])
  chrSex <- if (is.null(strSexCol)) rep(NA_character_, nRows) else NormaliseSex(dfResults[[strSexCol]])

  nLevel <- rep(NA_integer_, nRows)
  chrDirection <- rep(NA_character_, nRows)
  chrCriterion <- rep(NA_character_, nRows)
  # A record is "graded" once any applicable row has been evaluated against
  # it, even if the result met no level: that is a 0, not an NA.
  bGraded <- rep(FALSE, nRows)
  lSkipped <- list()

  chrTextCols <- c("Level1Text", "Level2Text", "Level3Text")
  bHasText <- all(chrTextCols %in% names(dfCriteria))

  for (i in seq_len(nrow(dfCriteria))) {
    dfRow <- dfCriteria[i, ]
    bRecord <- !is.na(chrParameter) & chrParameter == dfRow$Parameter & is.finite(nValue)
    if (!any(bRecord)) next

    # The sex-qualified rows need a sex; the fasting/random glucose rows and
    # the baseline-relative bases need columns this function does not take.
    strQualifier <- if (is.na(dfRow$Qualifier)) NA_character_ else tolower(dfRow$Qualifier)
    if (!is.na(strQualifier) && strQualifier %in% c("male", "males", "female", "females")) {
      if (is.null(strSexCol)) {
        lSkipped[["needs a sex column (strSexCol) for the sex-qualified rows"]] <-
          c(lSkipped[["needs a sex column (strSexCol) for the sex-qualified rows"]], dfRow$Parameter)
        next
      }
      bRecord <- bRecord & !is.na(chrSex) & chrSex == substr(strQualifier, 1, 1)
      if (!any(bRecord)) next
    } else if (!is.na(strQualifier)) {
      lSkipped[[paste0("qualifier '", dfRow$Qualifier, "' needs a column this function does not take")]] <-
        c(lSkipped[[paste0("qualifier '", dfRow$Qualifier, "' needs a column this function does not take")]], dfRow$Parameter)
      next
    }

    if (dfRow$Basis == "uln_multiple") {
      nCompare <- nMultiple
      bRecord <- bRecord & is.finite(nMultiple)
    } else if (dfRow$Basis == "absolute") {
      bUnit <- UnitMatches(chrUnit, dfRow$Unit, dfRow$Parameter)
      chrOther <- unique(dfResults[[strUnitCol]][bRecord & !bUnit])
      if (length(chrOther) > 0) {
        strReason <- paste0("unit differs from the criteria's (", dfRow$Unit, ")")
        lSkipped[[strReason]] <- c(lSkipped[[strReason]], paste0(dfRow$Parameter, " in ", chrOther))
      }
      bRecord <- bRecord & bUnit
      nCompare <- nValue
    } else {
      strReason <- paste0("basis '", dfRow$Basis, "' needs a baseline column this function does not take")
      lSkipped[[strReason]] <- c(lSkipped[[strReason]], dfRow$Parameter)
      next
    }
    if (!any(bRecord)) next

    nLevels <- c(dfRow$Level1, dfRow$Level2, dfRow$Level3)
    nMet <- rep(0L, nRows)
    for (k in which(!is.na(nLevels))) {
      bHit <- bRecord & switch(dfRow$Operator,
        "<" = nCompare < nLevels[k],
        "<=" = nCompare <= nLevels[k],
        ">" = nCompare > nLevels[k],
        ">=" = nCompare >= nLevels[k],
        gsm.core::stop_if(TRUE, message = paste0("Unknown Operator '", dfRow$Operator, "' in dfCriteria"))
      )
      bHit[is.na(bHit)] <- FALSE
      nMet[bHit] <- k
    }
    bGraded <- bGraded | bRecord
    bBetter <- bRecord & (is.na(nLevel) | nMet > nLevel)
    nLevel[bBetter] <- nMet[bBetter]
    bMet <- bBetter & nMet > 0
    chrDirection[bMet] <- dfRow$Direction
    chrCriterion[bMet] <- if (bHasText) {
      as.character(unlist(dfRow[chrTextCols]))[nMet[bMet]]
    } else {
      paste0(dfRow$Operator, nLevels[nMet[bMet]])
    }
  }

  nLevel[!bGraded] <- NA_integer_
  ReportSkipped("Derive_AbnormalityLevel", lSkipped)

  dfResults[[strOutCol]] <- as.integer(nLevel)
  dfResults[[strDirectionCol]] <- chrDirection
  dfResults[[strCriterionCol]] <- chrCriterion
  dfResults
}

#' Fold the spellings of sex to `m` or `f`
#' @param chrSex `character` Sex values.
#' @return `character` `"m"`, `"f"` or `NA`.
#' @keywords internal
NormaliseSex <- function(chrSex) {
  chrFirst <- substr(tolower(trimws(as.character(chrSex))), 1, 1)
  chrFirst[!(chrFirst %in% c("m", "f"))] <- NA_character_
  chrFirst
}

#' The default map from Table 56 and 57 parameters to `ExampleData("adbds")` test names
#'
#' Parameters the example data do not carry map to their own name, so a
#' dataset that uses the guide's spelling needs no map at all.
#'
#' @return Named `list` of `character`.
#' @keywords internal
DefaultAbnormalityParameters <- function() {
  list(
    "Sodium" = "Sodium",
    "Potassium" = "Potassium",
    "Chloride" = "Chloride",
    "Bicarbonate" = "Bicarbonate",
    "Blood urea nitrogen" = c("Blood Urea Nitrogen", "Blood urea nitrogen"),
    "Glucose" = "Glucose",
    "Calcium" = "Calcium",
    "Magnesium" = "Magnesium",
    "Phosphate" = "Phosphate",
    "Protein (total)" = c("Protein", "Protein (total)", "Total Protein"),
    "Albumin" = "Albumin",
    "CPK" = c("Creatine Kinase", "CPK"),
    "Amylase" = "Amylase",
    "Lipase" = "Lipase",
    "Creatinine" = "Creatinine",
    "eGFR" = "eGFR",
    "Alkaline phosphatase" = c("Alkaline Phosphatase", "Alkaline phosphatase"),
    "Alanine Aminotransferase" = "Alanine Aminotransferase",
    "Aspartate Aminotransferase" = "Aspartate Aminotransferase",
    "Total Bilirubin" = c("Bilirubin", "Total Bilirubin"),
    "Cholesterol (total)" = c("Cholesterol", "Cholesterol (total)", "Total Cholesterol"),
    "HDL" = "HDL",
    "LDL" = "LDL",
    "Triglycerides" = "Triglycerides",
    "WBC" = c("Leukocytes", "WBC"),
    "Hemoglobin" = "Hemoglobin",
    "Platelets" = c("Platelet", "Platelets"),
    "Lymphocytes" = "Lymphocytes",
    "Neutrophils" = "Neutrophils",
    "Eosinophils" = "Eosinophils",
    "PT" = c("Prothrombin Time", "PT"),
    "PTT" = c("Partial Thromboplastin Time", "PTT", "aPTT")
  )
}
