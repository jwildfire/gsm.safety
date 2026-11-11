#' Study-level count of participants who died
#'
#' The numerator step behind `saf0004`, the first of the census metrics. It
#' counts the participants a study's **death domain** records as having died,
#' anchored to the enrolled population, and hands
#' `gsm.core::Transform_Rate()` an ordinary `analyticsInput` frame.
#'
#' A participant has died if the death domain marks them, or, when
#' `dfStudyCompletion` is given, if their discontinuation reason is death in
#' any case (`"Death"`, `"DEATH"`, `"death"`). `Mapped_Death` is meant to be
#' that union already (`gsm.mapping::complete_death()`), but gsm.mapping 1.2.0
#' compares the reason against `"DEATH"` exactly, and a study that writes
#' `"Death"` loses those participants (#168). Reading the reason here keeps the
#' count independent of how the mapping spells it. The reason has to equal the
#' word: "Death of a relative" is not a death.
#'
#' @section Absent, empty, and zero are three different answers:
#'
#' The defect this metric replaces reported **one** death on a study whose
#' records hold thirteen, by text-matching a discontinuation reason. The defect
#' beside it reported **zero** where a column was missing. So the three states
#' are kept apart deliberately:
#'
#' | State | What the study said | What this returns |
#' |---|---|---|
#' | Absent | no death domain, or no `death` / ID column in it | an **error** |
#' | Empty | a death domain with no rows, and no completion domain with rows | **no row**, and a warning |
#' | Zero | a populated source marking nobody as died | a row reading **0** |
#'
#' A zero is a measurement — the domain ran and the answer was none. Absence is
#' not a measurement, and neither is a table with nothing in it, so neither is
#' allowed to render as a reassuring zero. Note that `gsm.core::CheckSpec()`
#' only *warns* on a declared column that is missing (it errors only on a
#' missing data.frame), so the column check has to live here for the guarantee
#' to hold.
#'
#' @section Counted once, and only if enrolled:
#'
#' Two rules the D0023 design makes standing, applied here rather than trusted:
#' the death domain is reduced to one row per participant before counting, so a
#' duplicated row cannot inflate the figure; and the count is anchored to
#' `dfSubjects`, so a participant identifier that appears in the death domain
#' but not in the enrolled population is never counted and the numerator can
#' never exceed its denominator.
#'
#' @param dfDeath `data.frame` Mapped death domain, one row per death record —
#'   `gsm.mapping`'s `Mapped_Death`. Rows it carries for other reasons (a
#'   progressive-disease date, say) have `death` missing rather than `TRUE`.
#' @param dfSubjects `data.frame` Mapped subject-level domain, the enrolled
#'   population — `gsm.mapping`'s `Mapped_SUBJ`. It is both the anchor and the
#'   denominator.
#' @param dfStudyCompletion `data.frame` or `NULL` Mapped study-completion
#'   domain, one row per completion record — `gsm.mapping`'s
#'   `Mapped_STUDCOMP`. When given, a participant whose `strReasonCol` is
#'   `strDeathReason` in any case and with surrounding spaces ignored counts as
#'   died. Default: `NULL`, the death domain alone, which the log says. A
#'   single string, which is what a workflow step receives when the domain it
#'   names was not supplied, is read as `NULL`.
#' @param strReasonCol `character` Discontinuation-reason column of
#'   `dfStudyCompletion`. Default: `"compreas"`.
#' @param strDeathReason `character` The reason, or reasons, that mean death,
#'   compared case-insensitively. Default: `"Death"`.
#' @param strIDCol `character` Participant ID column, shared by every domain.
#'   Default: `"subjid"`.
#' @param strDeathCol `character` Column of `dfDeath` marking a death. Read as
#'   true when logical `TRUE`, a non-zero number, or one of `"TRUE"`, `"T"`,
#'   `"Y"`, `"YES"`, `"1"`. Default: `"death"`.
#' @param strGroupCol `character` Grouping column in `dfSubjects`. Default:
#'   `"studyid"` — the study level this release publishes.
#' @param strGroupLevel `character` Group level to record. Default: `"Study"`.
#'   Moving the metric to site level is this argument plus `strGroupCol`, not a
#'   different metric.
#'
#' @return `data.frame` conforming to `analyticsInput` (`SubjectID`, `GroupID`,
#'   `GroupLevel`, `Numerator`, `Denominator`, `Metric`), one row per enrolled
#'   participant — or zero rows when both sources are empty.
#'
#' @examples
#' dfSubjects <- data.frame(subjid = c("S1", "S2"), studyid = "AA-AA-000-0000")
#' dfDeath <- data.frame(subjid = c("S1", "S2"), death = c(TRUE, NA))
#' Input_Deaths(dfDeath, dfSubjects)
#'
#' @export
Input_Deaths <- function(
    dfDeath,
    dfSubjects,
    dfStudyCompletion = NULL,
    strReasonCol = "compreas",
    strDeathReason = "Death",
    strIDCol = "subjid",
    strDeathCol = "death",
    strGroupCol = "studyid",
    strGroupLevel = "Study") {
  # --- Absent. Loud, never a zero. -------------------------------------------
  gsm.core::stop_if(
    cnd = !is.data.frame(dfDeath),
    message = paste0(
      "dfDeath is not a data.frame: this study supplies no death domain, ",
      "so the death count is absent rather than zero"
    )
  )
  gsm.core::stop_if(
    cnd = !is.data.frame(dfSubjects),
    message = "dfSubjects is not a data.frame"
  )
  for (strCol in c(strIDCol, strDeathCol)) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(dfDeath)),
      message = paste0("Column '", strCol, "' not found in dfDeath")
    )
  }
  for (strCol in c(strIDCol, strGroupCol)) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(dfSubjects)),
      message = paste0("Column '", strCol, "' not found in dfSubjects")
    )
  }
  # A workflow step names its inputs, and when the named domain was not
  # supplied the engine passes the name itself as a string: no completion
  # domain, so the count is the death domain's (#168).
  if (is.character(dfStudyCompletion) && length(dfStudyCompletion) == 1L) {
    dfStudyCompletion <- NULL
  }
  # Say which sources the count reads, so a domain that was not supplied
  # cannot quietly shorten it (#171).
  if (is.null(dfStudyCompletion)) {
    gsm.core::LogMessage(
      level = "info",
      message = paste0(
        "No study-completion domain was supplied, so the death count reads ",
        "the death domain alone."
      ),
      cli_detail = "alert_info"
    )
  }
  if (!is.null(dfStudyCompletion)) {
    gsm.core::stop_if(
      cnd = !is.data.frame(dfStudyCompletion),
      message = "dfStudyCompletion is not a data.frame"
    )
    for (strCol in c(strIDCol, strReasonCol)) {
      gsm.core::stop_if(
        cnd = !(strCol %in% names(dfStudyCompletion)),
        message = paste0("Column '", strCol, "' not found in dfStudyCompletion")
      )
    }
  }

  # One row per participant, on both sides, before anything is counted.
  dfSubjects <- dfSubjects[
    !duplicated(as.character(dfSubjects[[strIDCol]])), ,
    drop = FALSE
  ]

  # --- Empty. Sources with no rows have measured nothing. --------------------
  # The count is a union, so an empty death domain is empty only when there is
  # no completion domain with rows to read either (#171).
  if (nrow(dfDeath) == 0 &&
    (is.null(dfStudyCompletion) || nrow(dfStudyCompletion) == 0)) {
    gsm.core::LogMessage(
      level = "warn",
      message = paste0(
        "The death domain is empty, so no death figure is published. ",
        "An empty domain is not a count of zero."
      )
    )
    return(data.frame(
      SubjectID = character(0),
      GroupID = character(0),
      GroupLevel = character(0),
      Numerator = numeric(0),
      Denominator = numeric(0),
      Metric = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  # --- Zero or more. A populated domain is a measurement. --------------------
  bDied <- DeathFlagIsTrue(dfDeath[[strDeathCol]])
  chrDied <- as.character(dfDeath[[strIDCol]])[bDied]
  if (!is.null(dfStudyCompletion)) {
    bReason <- ReasonIsDeath(dfStudyCompletion[[strReasonCol]], strDeathReason)
    chrDied <- c(chrDied, as.character(dfStudyCompletion[[strIDCol]])[bReason])
  }
  chrDied <- unique(chrDied)
  chrDied <- chrDied[!is.na(chrDied) & nzchar(chrDied)]

  dfNumerator <- stats::setNames(
    data.frame(chrDied, stringsAsFactors = FALSE),
    strIDCol
  )

  gsm.core::Input_Rate(
    dfSubjects = dfSubjects,
    dfNumerator = dfNumerator,
    dfDenominator = dfSubjects,
    strSubjectCol = strIDCol,
    strGroupCol = strGroupCol,
    strGroupLevel = strGroupLevel,
    strNumeratorMethod = "Count",
    strDenominatorMethod = "Count"
  )
}

#' Is a death flag true, whichever way the study spells it?
#'
#' `Mapped_Death$death` is logical by spec, but a study can arrive with the
#' column as a character or numeric flag. Missing is never true: a row carried
#' for some other reason must not read as a death.
#'
#' @param x Vector to read as a death flag.
#'
#' @return `logical` of `length(x)`.
#'
#' @keywords internal
DeathFlagIsTrue <- function(x) {
  if (is.logical(x)) {
    return(!is.na(x) & x)
  }
  if (is.numeric(x)) {
    return(!is.na(x) & x != 0)
  }
  toupper(trimws(as.character(x))) %in% c("TRUE", "T", "Y", "YES", "1")
}

# A discontinuation reason that is the death reason, compared without regard to
# case or surrounding spaces (#168). Missing reasons are not deaths.
ReasonIsDeath <- function(x, strDeathReason = "Death") {
  chrReason <- toupper(trimws(as.character(x)))
  !is.na(chrReason) & chrReason %in% toupper(trimws(strDeathReason))
}
