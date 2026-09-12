#' Flag results beyond the FDA extreme-value thresholds
#'
#' Adds the flag the FDA Standard Safety Tables and Figures Integrated Guide
#' v2.0 removes records on: a result below the low or above the high threshold
#' of Appendix Tables 58 (chemistry), 59 (hematology) or 60 (vital signs) is
#' treated as a likely laboratory or recording error and excluded from the
#' mean change from baseline over time figures (sections 2.4, 2.4.2, 2.5.1).
#' Requirement `FDA-RULE-004`; the unit matching is `FDA-RULE-005`.
#'
#' The guide prints every threshold in US-conventional and SI units, and
#' [FDA_ExtremeValues] carries both. A record is compared against the row for
#' the unit it carries: a result in `mg/dL` against the US thresholds, in
#' `mmol/L` against the SI ones. A record whose unit matches neither is left
#' `NA` and named in a message rather than compared on the wrong scale;
#' spellings of the same unit are folded (and mEq/L and mmol/L treated as one
#' unit for the monovalent electrolytes only) but nothing is converted. A missing
#' threshold in one direction (an `N/A` in the guide) is no bound in that
#' direction, and the threshold itself is not extreme.
#'
#' The flag is added, never applied: nothing is dropped or aggregated, and the
#' renderer that draws a mean-change figure filters on it (the design's L1
#' contract).
#'
#' @param dfResults `data.frame` Long-format results, one row per participant
#'   per test per visit, in the shape of `ExampleData("adbds")`.
#' @param dfThresholds `data.frame` The thresholds, in the shape of
#'   [FDA_ExtremeValues] (at least `Parameter`, `UnitSystem`, `Unit`, `Low`,
#'   `High`). Default: `FDA_ExtremeValues`.
#' @param strTestCol `character` Column holding the test name. Default: `"TEST"`.
#' @param strValueCol `character` Numeric result column. Default: `"STRESN"`.
#' @param strUnitCol `character` Unit column. Default: `"STRESU"`.
#' @param lParameterValues Named `list` mapping each threshold `Parameter` to
#'   the test name(s) the data use for it. Default: the names
#'   `ExampleData("adbds")` uses.
#' @param strOutCol `character` Name of the flag column. Default:
#'   `"ExtremeValueFlag"`; the direction is added as `<strOutCol>` with
#'   `Flag` replaced by `Direction`. Neither may already be a column of
#'   `dfResults`: the function appends, it never overwrites.
#'
#' @return `dfResults` with two columns appended: the flag (`logical`, `TRUE`
#'   beyond a threshold, `FALSE` within, `NA` where the parameter or unit could
#'   not be matched or the result is missing) and the direction (`"low"`,
#'   `"high"` or `NA`).
#'
#' @examples
#' dfLabs <- ExampleData("adbds")
#' dfLabs <- Derive_ExtremeValueFlag(dfLabs)
#' table(matched = !is.na(dfLabs$ExtremeValueFlag), extreme = dfLabs$ExtremeValueFlag, useNA = "ifany")
#'
#' @seealso [FDA_ExtremeValues] for the thresholds and their provenance.
#' @family FDA derivations
#' @export
Derive_ExtremeValueFlag <- function(
    dfResults,
    dfThresholds = gsm.safety::FDA_ExtremeValues,
    strTestCol = "TEST",
    strValueCol = "STRESN",
    strUnitCol = "STRESU",
    lParameterValues = DefaultExtremeParameters(),
    strOutCol = "ExtremeValueFlag") {
  RequireResultColumns(dfResults, c(strTestCol, strValueCol, strUnitCol))
  RequireOutColToken(strOutCol, "Flag")
  strDirectionCol <- sub("Flag", "Direction", strOutCol)
  RequireNewColumns(dfResults, c(strOutCol, strDirectionCol))
  RequireResultColumns(
    dfThresholds, c("Parameter", "UnitSystem", "Unit", "Low", "High"),
    strName = "dfThresholds"
  )

  nRows <- nrow(dfResults)
  chrParameter <- ResolveParameters(dfResults[[strTestCol]], lParameterValues)
  nValue <- suppressWarnings(as.numeric(dfResults[[strValueCol]]))
  chrUnit <- NormaliseUnit(dfResults[[strUnitCol]])

  bFlag <- rep(NA, nRows)
  chrDirection <- rep(NA_character_, nRows)
  bMatched <- rep(FALSE, nRows)

  for (i in seq_len(nrow(dfThresholds))) {
    dfRow <- dfThresholds[i, ]
    bRecord <- !is.na(chrParameter) & chrParameter == dfRow$Parameter & is.finite(nValue) &
      !is.na(dfRow$Unit) & UnitMatches(chrUnit, dfRow$Unit, dfRow$Parameter)
    if (is.na(dfRow$Unit)) {
      # A unitless parameter (INR) matches a blank or missing unit.
      bRecord <- !is.na(chrParameter) & chrParameter == dfRow$Parameter & is.finite(nValue) &
        (is.na(chrUnit) | chrUnit == "")
    }
    if (!any(bRecord)) next

    bLow <- bRecord & !is.na(dfRow$Low) & nValue < dfRow$Low
    bHigh <- bRecord & !is.na(dfRow$High) & nValue > dfRow$High
    bLow[is.na(bLow)] <- FALSE
    bHigh[is.na(bHigh)] <- FALSE

    bFlag[bRecord & !bMatched] <- FALSE
    bFlag[bLow | bHigh] <- TRUE
    chrDirection[bLow] <- "low"
    chrDirection[bHigh] <- "high"
    bMatched <- bMatched | bRecord
  }

  # Records whose parameter is known but whose unit matched no row.
  bUnmatchedUnit <- !is.na(chrParameter) & is.finite(nValue) & !bMatched
  lSkipped <- list()
  if (any(bUnmatchedUnit)) {
    lSkipped[["unit matches neither the US-conventional nor the SI threshold row"]] <-
      unique(paste0(chrParameter[bUnmatchedUnit], " in ", dfResults[[strUnitCol]][bUnmatchedUnit]))
  }
  ReportSkipped("Derive_ExtremeValueFlag", lSkipped)

  dfResults[[strOutCol]] <- bFlag
  dfResults[[strDirectionCol]] <- chrDirection
  dfResults
}

#' The default map from Table 58 to 60 parameters to `ExampleData("adbds")` test names
#'
#' @return Named `list` of `character`.
#' @keywords internal
DefaultExtremeParameters <- function() {
  list(
    "Sodium" = "Sodium",
    "Potassium" = "Potassium",
    "Chloride" = "Chloride",
    "Bicarbonate" = "Bicarbonate",
    "Blood Urea Nitrogen" = c("Blood Urea Nitrogen", "Blood urea nitrogen"),
    "Glucose" = "Glucose",
    "Total Calcium" = c("Calcium", "Total Calcium"),
    "Magnesium" = "Magnesium",
    "Phosphate" = "Phosphate",
    "Total Protein" = c("Protein", "Total Protein"),
    "Albumin" = "Albumin",
    "Total CPK" = c("Creatine Kinase", "CPK", "Total CPK"),
    "Amylase" = "Amylase",
    "Lipase" = "Lipase",
    "Creatinine" = "Creatinine",
    "Creatinine Clearance" = "Creatinine Clearance",
    "eGFR" = "eGFR",
    "Alkaline Phosphatase" = "Alkaline Phosphatase",
    "Alanine Aminotransferase" = "Alanine Aminotransferase",
    "Aspartate Aminotransferase" = "Aspartate Aminotransferase",
    "GGT" = c("Gamma Glutamyl Transferase", "GGT"),
    "Total Bilirubin" = c("Bilirubin", "Total Bilirubin"),
    "Total Cholesterol" = c("Cholesterol", "Total Cholesterol"),
    "HDL" = "HDL",
    "LDL" = "LDL",
    "Triglycerides" = "Triglycerides",
    "Neutrophils" = "Neutrophils",
    "Lymphocytes" = "Lymphocytes",
    "Eosinophils" = "Eosinophils",
    "Hemoglobin" = "Hemoglobin",
    "Hematocrit" = "Hematocrit",
    "Platelets" = c("Platelet", "Platelets"),
    "PT" = c("Prothrombin Time", "PT"),
    "PTT" = c("Partial Thromboplastin Time", "PTT", "aPTT"),
    "INR" = "INR",
    "Pulse" = c("Pulse Rate", "Pulse", "Heart Rate"),
    "Blood pressure systolic" = "Systolic Blood Pressure",
    "Blood pressure diastolic" = "Diastolic Blood Pressure",
    "Respiration" = c("Respiratory Rate", "Respiration"),
    "Temperature" = "Temperature"
  )
}
