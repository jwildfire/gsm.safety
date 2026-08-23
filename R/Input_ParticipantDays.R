#' Study-level total of participant-days
#'
#' The numerator step behind `saf0008` and `saf0009`, the two person-time
#' figures. It sums a day column of the enrolled population — `timeonstudy` or
#' `timeontreatment` — and hands `gsm.core::Transform_Rate()` an ordinary
#' `analyticsInput` frame whose `Numerator` is the total days and whose
#' `Denominator` is the participants who contributed them.
#'
#' @section Days, not years:
#'
#' The figure published is the number actually summed, in the unit the subject
#' domain records it in. The census report is where person-years are presented,
#' and it divides. A metric that published years would be publishing a figure
#' nothing in the pipeline can check against the domain it came from.
#'
#' @section Missing person-time is not zero days:
#'
#' `Numerator / Denominator` is the mean days per participant, so a participant
#' whose person-time was never recorded cannot stay in one side of the fraction
#' and leave the other: counting them as zero days would understate the total
#' and inflate the denominator at once. They leave both, and a warning names
#' them. A *recorded* zero is different — it is a measurement, and stays.
#'
#' Negative person-time is treated the same way. It is not a duration, so it is
#' not summed, and the warning says how many participants it happened to.
#'
#' @param dfSubjects `data.frame` Mapped subject-level domain, the enrolled
#'   population — `gsm.mapping`'s `Mapped_SUBJ`.
#' @param strDayCol `character` Column of `dfSubjects` holding person-time in
#'   days, e.g. `"timeonstudy"` or `"timeontreatment"`.
#' @param strIDCol `character` Participant ID column. Default: `"subjid"`.
#' @param strDomainName `character` Name of the mapped domain, used in the
#'   errors a reader has to act on. Default: `"dfSubjects"`.
#' @param strGroupCol `character` Grouping column in `dfSubjects`. Default:
#'   `"studyid"`.
#' @param strGroupLevel `character` Group level to record. Default: `"Study"`.
#'
#' @return `data.frame` conforming to `analyticsInput` (`SubjectID`, `GroupID`,
#'   `GroupLevel`, `Numerator`, `Denominator`, `Metric`), one row per
#'   contributing participant — or zero rows when nothing was measured.
#'
#' @examples
#' dfSubjects <- data.frame(
#'   subjid = c("S1", "S2"),
#'   studyid = "AA-AA-000-0000",
#'   timeonstudy = c(120, 90)
#' )
#' Input_ParticipantDays(dfSubjects, "timeonstudy")
#'
#' @export
Input_ParticipantDays <- function(
    dfSubjects,
    strDayCol,
    strIDCol = "subjid",
    strDomainName = "dfSubjects",
    strGroupCol = "studyid",
    strGroupLevel = "Study") {
  # --- Absent. Loud, never a zero. -------------------------------------------
  .RequireFrame(dfSubjects, strDomainName)
  .RequireColumns(dfSubjects, c(strIDCol, strGroupCol, strDayCol), strDomainName)

  dfSubjects <- .OnePerParticipant(dfSubjects, strIDCol)

  # --- No population. Not a denominator of zero. -----------------------------
  if (.NoEnrolledPopulation(dfSubjects)) {
    return(.NoFigure())
  }

  nDays <- ParticipantDayValues(dfSubjects[[strDayCol]], strDayCol, strDomainName)

  # --- Person-time that is not a duration leaves both sides together. --------
  bMissing <- is.na(nDays)
  bNegative <- !bMissing & nDays < 0
  if (any(bMissing | bNegative)) {
    chrWhy <- c(
      if (any(bMissing)) {
        paste0(
          sum(bMissing), " with no recorded value (",
          .NameParticipants(dfSubjects[[strIDCol]][bMissing]), ")"
        )
      },
      if (any(bNegative)) {
        paste0(
          sum(bNegative), " with a negative value (",
          .NameParticipants(dfSubjects[[strIDCol]][bNegative]), ")"
        )
      }
    )
    gsm.core::LogMessage(
      level = "warn",
      message = paste0(
        "Person-time in '", strDayCol, "' is not a duration for ",
        sum(bMissing | bNegative), " of ", length(nDays), " participants: ",
        paste(chrWhy, collapse = "; "),
        ". They leave the total and the denominator together, because ",
        "missing days are not zero days."
      )
    )
    dfSubjects <- dfSubjects[!(bMissing | bNegative), , drop = FALSE]
    nDays <- nDays[!(bMissing | bNegative)]
  }

  # --- Nobody left. Nothing measured, so nothing published. ------------------
  if (nrow(dfSubjects) == 0) {
    gsm.core::LogMessage(
      level = "warn",
      message = paste0(
        "No participant has a recorded person-time in '", strDayCol,
        "', so no figure is published. A column nobody filled in is not a ",
        "total of zero days."
      )
    )
    return(.NoFigure())
  }

  dfNumerator <- stats::setNames(
    data.frame(
      as.character(dfSubjects[[strIDCol]]), as.numeric(nDays),
      stringsAsFactors = FALSE
    ),
    c(strIDCol, "Days")
  )

  gsm.core::Input_Rate(
    dfSubjects = dfSubjects,
    dfNumerator = dfNumerator,
    dfDenominator = dfSubjects,
    strSubjectCol = strIDCol,
    strGroupCol = strGroupCol,
    strGroupLevel = strGroupLevel,
    strNumeratorMethod = "Sum",
    strNumeratorCol = "Days",
    strDenominatorMethod = "Count"
  )
}

#' Read a person-time column as days
#'
#' A column that is not a number is an error, not a column of missing values.
#' A study whose `timeonstudy` arrived as free text has not recorded zero days
#' for everybody; it has recorded something this metric cannot read, and
#' silently reading it as missing is the defect shape this rebuild removes.
#'
#' @param vDays Vector to read as person-time in days.
#' @param strDayCol `character` Column name, for the message.
#' @param strDomainName `character` Domain name, for the message.
#'
#' @return `numeric` of `length(vDays)`, missing where the study recorded
#'   nothing.
#'
#' @keywords internal
ParticipantDayValues <- function(vDays, strDayCol, strDomainName = "dfSubjects") {
  if (is.numeric(vDays)) {
    return(as.numeric(vDays))
  }

  chrDays <- trimws(as.character(vDays))
  bRecorded <- !is.na(chrDays) & nzchar(chrDays)
  nDays <- suppressWarnings(as.numeric(chrDays))
  gsm.core::stop_if(
    cnd = any(bRecorded & is.na(nDays)),
    message = paste0(
      "Column '", strDayCol, "' of ", strDomainName, " must be numeric: it ",
      "records person-time in days, and ",
      sum(bRecorded & is.na(nDays)), " recorded values cannot be read as a ",
      "number"
    )
  )
  nDays
}
