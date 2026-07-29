#' Study census, exposure and data coverage for a safety overview
#'
#' The denominators a safety reader needs *before* any event count means
#' anything: how many participants there are, how many are on treatment, how
#' much person-time has accrued, who has left the study and why, and — the one
#' most often missing — how completely the safety data itself has been
#' collected.
#'
#' Coverage is not decoration. A low event rate at a visit where 40% of
#' participants have no lab result is not reassurance, and the only way to tell
#' those two situations apart is to publish the denominator beside the count.
#' `Coverage` therefore reports, per visit, how many participants have at least
#' one result against how many are expected.
#'
#' Every figure is **pooled across treatment arms**. A study-team safety view is
#' a blinded view, and FDA guidance treats even coded arms (A/B/C) as unblinded
#' data, so no arm split is produced here.
#'
#' @param dfSubjects `data.frame` Subject-level domain, one row per participant.
#' @param dfLabs `data.frame` or `NULL` Long-format lab results, for lab
#'   coverage by visit.
#' @param dfECG `data.frame` or `NULL` Long-format ECG records, for ECG coverage
#'   by visit.
#' @param dfAE `data.frame` or `NULL` Adverse events, for the AE reporting rate.
#' @param dfDisposition `data.frame` or `NULL` Study-completion domain, for
#'   disposition and deaths.
#' @param strIDCol `character` Participant ID column, shared by every domain.
#'   Default: `"subjid"`.
#' @param strArmCol `character` Treatment arm column in `dfSubjects`; used only
#'   to count randomised participants, never to split a figure.
#'   Default: `"arm"`.
#' @param strTimeOnStudyCol,strTimeOnTreatmentCol `character` Person-time
#'   columns in `dfSubjects`, in days. Defaults: `"timeonstudy"`,
#'   `"timeontreatment"`.
#' @param strLabVisitCol,strLabVisitNumCol `character` Visit label and visit
#'   number columns in `dfLabs`. Defaults: `"visnam"`, `"visnum"`.
#' @param strECGVisitCol,strECGVisitNumCol `character` Visit label and visit
#'   number columns in `dfECG`. Defaults: `"visnam"`, `"visnum"`.
#' @param strCompleteCol,strReasonCol `character` Completion flag and reason
#'   columns in `dfDisposition`. Defaults: `"compyn"`, `"compreas"`.
#' @param chrDeathValues `character` Values of the disposition reason column
#'   read as death. Default: `c("DEATH", "DIED")`.
#'
#' @return `list` with three data.frames:
#'   * `Census` — one row per named figure (`Label`, `Value`, `Denominator`,
#'     `Group`), the study's denominators and exposure;
#'   * `Coverage` — one row per domain per visit (`Domain`, `Visit`, `VisitNum`,
#'     `Participants`, `Expected`), data availability;
#'   * `Disposition` — one row per disposition state (`State`, `Participants`).
#'
#' @examples
#' dfSubjects <- data.frame(
#'   subjid = c("S1", "S2", "S3"),
#'   arm = c("A", "A", NA),
#'   timeonstudy = c(120, 90, 30),
#'   timeontreatment = c(110, 80, 0)
#' )
#' SafetyCensus(dfSubjects)$Census
#'
#' @export
SafetyCensus <- function(
    dfSubjects,
    dfLabs = NULL,
    dfECG = NULL,
    dfAE = NULL,
    dfDisposition = NULL,
    strIDCol = "subjid",
    strArmCol = "arm",
    strTimeOnStudyCol = "timeonstudy",
    strTimeOnTreatmentCol = "timeontreatment",
    strLabVisitCol = "visnam",
    strLabVisitNumCol = "visnum",
    strECGVisitCol = "visnam",
    strECGVisitNumCol = "visnum",
    strCompleteCol = "compyn",
    strReasonCol = "compreas",
    chrDeathValues = c("DEATH", "DIED")) {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfSubjects),
    message = "dfSubjects is not a data.frame"
  )
  gsm.core::stop_if(
    cnd = !(strIDCol %in% names(dfSubjects)),
    message = paste0("Column '", strIDCol, "' not found in dfSubjects")
  )

  chrEnrolled <- unique(as.character(dfSubjects[[strIDCol]]))
  chrEnrolled <- chrEnrolled[!is.na(chrEnrolled) & nzchar(chrEnrolled)]
  nEnrolled <- length(chrEnrolled)

  NumericCol <- function(df, strCol) {
    if (is.null(df) || !(strCol %in% names(df))) {
      return(rep(NA_real_, if (is.null(df)) 0L else nrow(df)))
    }
    suppressWarnings(as.numeric(df[[strCol]]))
  }
  nOnStudy <- NumericCol(dfSubjects, strTimeOnStudyCol)
  nOnTreatment <- NumericCol(dfSubjects, strTimeOnTreatmentCol)

  nRandomised <- if (strArmCol %in% names(dfSubjects)) {
    chrArm <- trimws(as.character(dfSubjects[[strArmCol]]))
    length(unique(as.character(dfSubjects[[strIDCol]])[!is.na(chrArm) & nzchar(chrArm)]))
  } else {
    NA_real_
  }
  nDosed <- sum(is.finite(nOnTreatment) & nOnTreatment > 0)

  # Disposition. Kept separate from the census counts because a study whose
  # disposition domain covers only part of the population must say so rather
  # than report the uncovered participants as ongoing.
  dfDisp <- data.frame(
    State = character(0), Participants = numeric(0),
    stringsAsFactors = FALSE
  )
  nDeaths <- NA_real_
  nCovered <- 0
  if (!is.null(dfDisposition) && nrow(dfDisposition) > 0 &&
    strIDCol %in% names(dfDisposition)) {
    chrDispID <- as.character(dfDisposition[[strIDCol]])
    nCovered <- length(unique(chrDispID))
    chrComplete <- if (strCompleteCol %in% names(dfDisposition)) {
      toupper(trimws(as.character(dfDisposition[[strCompleteCol]])))
    } else {
      rep("", nrow(dfDisposition))
    }
    chrReason <- if (strReasonCol %in% names(dfDisposition)) {
      toupper(trimws(as.character(dfDisposition[[strReasonCol]])))
    } else {
      rep("", nrow(dfDisposition))
    }
    bDeath <- chrReason %in% toupper(chrDeathValues)
    nDeaths <- length(unique(chrDispID[bDeath]))

    chrState <- ifelse(
      bDeath, "Died",
      ifelse(chrComplete %in% c("Y", "YES"), "Completed",
        ifelse(chrComplete %in% c("N", "NO"),
          ifelse(nzchar(chrReason), paste0("Discontinued - ", .TitleCase(chrReason)), "Discontinued"),
          "Ongoing"
        )
      )
    )
    tState <- table(chrState)
    dfDisp <- data.frame(
      State = names(tState),
      Participants = as.numeric(tState),
      stringsAsFactors = FALSE
    )
    dfDisp <- dfDisp[order(-dfDisp$Participants), , drop = FALSE]
    if (nCovered < nEnrolled) {
      dfDisp <- rbind(dfDisp, data.frame(
        State = "Not in the disposition domain",
        Participants = nEnrolled - nCovered,
        stringsAsFactors = FALSE
      ))
    }
    rownames(dfDisp) <- NULL
  }

  CountAssessed <- function(df) {
    if (is.null(df) || nrow(df) == 0 || !(strIDCol %in% names(df))) {
      return(NA_real_)
    }
    length(intersect(unique(as.character(df[[strIDCol]])), chrEnrolled))
  }

  dfCensus <- rbind(
    .CensusRow("Enrolled participants", nEnrolled, NA, "Census"),
    .CensusRow("Randomised to an arm", nRandomised, nEnrolled, "Census"),
    .CensusRow("Received study drug", nDosed, nEnrolled, "Census"),
    .CensusRow("Deaths", nDeaths, nEnrolled, "Census"),
    .CensusRow("Person-years on study", .PersonYears(nOnStudy), NA, "Exposure"),
    .CensusRow("Person-years on treatment", .PersonYears(nOnTreatment), NA, "Exposure"),
    .CensusRow("Median days on treatment", .SafeMedian(nOnTreatment), NA, "Exposure"),
    .CensusRow("Participants with a lab result", CountAssessed(dfLabs), nEnrolled, "Follow-up"),
    .CensusRow("Participants with an ECG", CountAssessed(dfECG), nEnrolled, "Follow-up"),
    .CensusRow("Participants with a reported AE", CountAssessed(dfAE), nEnrolled, "Follow-up"),
    .CensusRow("Participants with a disposition record", if (nCovered > 0) nCovered else NA, nEnrolled, "Follow-up")
  )

  dfCoverage <- rbind(
    .VisitCoverage(dfLabs, "Labs", strIDCol, strLabVisitCol, strLabVisitNumCol, nEnrolled),
    .VisitCoverage(dfECG, "ECG", strIDCol, strECGVisitCol, strECGVisitNumCol, nEnrolled)
  )

  list(Census = dfCensus, Coverage = dfCoverage, Disposition = dfDisp)
}

#' One row of the census table
#' @keywords internal
.CensusRow <- function(strLabel, nValue, nDenominator, strGroup) {
  data.frame(
    Label = strLabel,
    Value = if (length(nValue) == 1 && is.finite(nValue)) as.numeric(nValue) else NA_real_,
    Denominator = if (length(nDenominator) == 1 && is.finite(nDenominator)) {
      as.numeric(nDenominator)
    } else {
      NA_real_
    },
    Group = strGroup,
    stringsAsFactors = FALSE
  )
}

#' Person-years from a vector of person-days
#' @keywords internal
.PersonYears <- function(nDays) {
  if (!any(is.finite(nDays))) {
    return(NA_real_)
  }
  round(sum(nDays[is.finite(nDays)]) / 365.25, 1)
}

#' Median of the finite, positive values, or NA
#' @keywords internal
.SafeMedian <- function(nValues) {
  nValues <- nValues[is.finite(nValues) & nValues > 0]
  if (!length(nValues)) {
    return(NA_real_)
  }
  round(stats::median(nValues), 1)
}

#' Title-case a shouted disposition reason
#' @keywords internal
.TitleCase <- function(chrText) {
  vapply(
    strsplit(tolower(chrText), " ", fixed = TRUE),
    function(chrWords) {
      paste(sub("^(.)", "\\U\\1", chrWords, perl = TRUE), collapse = " ")
    },
    character(1)
  )
}

#' Participants with at least one record, per visit
#' @keywords internal
.VisitCoverage <- function(df, strDomain, strIDCol, strVisitCol, strVisitNumCol, nExpected) {
  dfEmpty <- data.frame(
    Domain = character(0), Visit = character(0), VisitNum = numeric(0),
    Participants = numeric(0), Expected = numeric(0),
    stringsAsFactors = FALSE
  )
  if (is.null(df) || nrow(df) == 0 ||
    !all(c(strIDCol, strVisitCol) %in% names(df))) {
    return(dfEmpty)
  }
  chrVisit <- as.character(df[[strVisitCol]])
  chrID <- as.character(df[[strIDCol]])
  bKeep <- !is.na(chrVisit) & nzchar(chrVisit)
  if (!any(bKeep)) {
    return(dfEmpty)
  }

  vCount <- tapply(chrID[bKeep], chrVisit[bKeep], function(x) length(unique(x)))
  nVisitNum <- if (strVisitNumCol %in% names(df)) {
    suppressWarnings(as.numeric(df[[strVisitNumCol]]))
  } else {
    rep(NA_real_, nrow(df))
  }
  vOrder <- tapply(nVisitNum[bKeep], chrVisit[bKeep], function(x) {
    x <- x[is.finite(x)]
    if (length(x)) min(x) else NA_real_
  })

  out <- data.frame(
    Domain = strDomain,
    Visit = names(vCount),
    VisitNum = as.numeric(vOrder[names(vCount)]),
    Participants = as.numeric(vCount),
    Expected = as.numeric(nExpected),
    stringsAsFactors = FALSE
  )
  out <- out[order(out$VisitNum, out$Visit), , drop = FALSE]
  rownames(out) <- NULL
  out
}
