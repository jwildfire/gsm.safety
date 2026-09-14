#' Study-level count of participants who died
#'
#' The numerator step behind `saf0004`, the first of the census metrics. It
#' counts the participants a study's **death domain** records as having died,
#' anchored to the enrolled population, and hands
#' `gsm.core::Transform_Rate()` an ordinary `analyticsInput` frame.
#'
#' No clinical definition of death is written here. `Mapped_Death` is
#' gsm.mapping's own union of the death domain and the study-completion
#' domain's discontinuation reason (`gsm.mapping::complete_death()`); this
#' function counts the participants that union marks, and nothing else.
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
#' | Empty | a death domain with no rows at all | **no row**, and a warning |
#' | Zero | a populated death domain marking nobody as died | a row reading **0** |
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
#' @param strIDCol `character` Participant ID column, shared by both domains.
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
#'   participant — or zero rows when the death domain is empty.
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

  # One row per participant, on both sides, before anything is counted.
  dfSubjects <- dfSubjects[
    !duplicated(as.character(dfSubjects[[strIDCol]])), ,
    drop = FALSE
  ]

  # --- Empty. A table with no rows has measured nothing. ---------------------
  if (nrow(dfDeath) == 0) {
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
  chrDied <- unique(as.character(dfDeath[[strIDCol]])[bDied])
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
