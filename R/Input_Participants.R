#' Study-level count of the participants a domain names
#'
#' The numerator step behind most of the census metrics: `saf0005` and
#' `saf0007`, `saf0010` through `saf0015`. It counts the participants a mapped
#' domain names — optionally only those whose column matches a value, or whose
#' column records anything at all — anchored to the enrolled population, and
#' hands `gsm.core::Transform_Rate()` an ordinary `analyticsInput` frame.
#'
#' One step, eight metrics. The differences between "participants with a lab
#' result" and "participants who completed" are which domain is read, which
#' column is looked at and which value is matched, and all three are declared
#' in the metric definition. Writing the arithmetic once is deliberate: eight
#' hand-written counting steps are eight chances to write one of them wrong,
#' which is the defect this rebuild exists to remove.
#'
#' @section Absent, empty, and zero are three different answers:
#'
#' | State | What the study said | What this returns |
#' |---|---|---|
#' | Absent | no domain, or no declared column in it | an **error** |
#' | Empty | a domain with no rows at all | **no row**, and a warning |
#' | Zero | a populated domain naming nobody | a row reading **0** |
#'
#' A zero is a measurement — the domain ran and the answer was none. Absence is
#' not a measurement, and neither is a table with nothing in it, so neither is
#' allowed to render as a reassuring zero. `gsm.core::CheckSpec()` only *warns*
#' on a declared column that is missing (it errors only on a missing
#' data.frame), so the column check lives here for the guarantee to hold.
#'
#' A subject domain with no rows is a fourth state: no denominator at all.
#' Nothing is published, and a warning says why.
#'
#' @section Counted once, and only if enrolled:
#'
#' Two rules the D0023 design makes standing, applied here rather than trusted:
#' the domain is reduced to one row per participant before counting, so a
#' duplicated row cannot inflate the figure; and the count is anchored to
#' `dfSubjects`, so a participant identifier that appears in the domain but not
#' in the enrolled population is never counted and the numerator can never
#' exceed its denominator.
#'
#' @param dfDomain `data.frame` Mapped domain to count participants from.
#' @param dfSubjects `data.frame` Mapped subject-level domain, the enrolled
#'   population — `gsm.mapping`'s `Mapped_SUBJ`. It is both the anchor and the
#'   denominator.
#' @param strIDCol `character` Participant ID column, shared by both domains.
#'   Default: `"subjid"`.
#' @param strFilterCol `character` or `NULL` Column of `dfDomain` that decides
#'   whether a participant counts. `NULL` (the default) counts every
#'   participant the domain names.
#' @param strFilterValues `character` or `NULL` Values of `strFilterCol` that
#'   count, compared without regard to case or surrounding space. Several are
#'   written comma-separated — `"Y, N"` — following the ecosystem's convention
#'   for a multi-valued meta scalar. `NULL` (the default) counts a participant
#'   whose `strFilterCol` records *anything*: not missing, not blank.
#' @param strDomainName `character` Name of the mapped domain, used in the
#'   errors a reader has to act on. Default: `"dfDomain"`.
#' @param strGroupCol `character` Grouping column in `dfSubjects`. Default:
#'   `"studyid"` — the study level this release publishes.
#' @param strGroupLevel `character` Group level to record. Default: `"Study"`.
#'   Moving a metric to site level is this argument plus `strGroupCol`, not a
#'   different metric.
#'
#' @return `data.frame` conforming to `analyticsInput` (`SubjectID`, `GroupID`,
#'   `GroupLevel`, `Numerator`, `Denominator`, `Metric`), one row per enrolled
#'   participant — or zero rows when nothing was measured.
#'
#' @examples
#' dfSubjects <- data.frame(subjid = c("S1", "S2"), studyid = "AA-AA-000-0000")
#' dfDisposition <- data.frame(subjid = c("S1", "S2"), compyn = c("Y", "N"))
#'
#' # Participants with a disposition record
#' Input_Participants(dfDisposition, dfSubjects)
#'
#' # Participants who completed
#' Input_Participants(
#'   dfDisposition, dfSubjects,
#'   strFilterCol = "compyn", strFilterValues = "Y"
#' )
#'
#' @export
Input_Participants <- function(
    dfDomain,
    dfSubjects,
    strIDCol = "subjid",
    strFilterCol = NULL,
    strFilterValues = NULL,
    strDomainName = "dfDomain",
    strGroupCol = "studyid",
    strGroupLevel = "Study") {
  # --- Absent. Loud, never a zero. -------------------------------------------
  .RequireFrame(dfDomain, strDomainName)
  .RequireFrame(dfSubjects, "dfSubjects")
  .RequireColumns(dfDomain, c(strIDCol, strFilterCol), strDomainName)
  .RequireColumns(dfSubjects, c(strIDCol, strGroupCol), "dfSubjects")

  # One row per participant, on both sides, before anything is counted.
  dfSubjects <- .OnePerParticipant(dfSubjects, strIDCol)

  # --- No population. Not a denominator of zero. -----------------------------
  if (.NoEnrolledPopulation(dfSubjects)) {
    return(.NoFigure())
  }

  # --- Empty. A table with no rows has measured nothing. ---------------------
  if (nrow(dfDomain) == 0) {
    gsm.core::LogMessage(
      level = "warn",
      message = paste0(
        strDomainName, " is empty, so no figure is published. ",
        "An empty domain is not a count of zero."
      )
    )
    return(.NoFigure())
  }

  # --- Zero or more. A populated domain is a measurement. --------------------
  bCounts <- ParticipantCounts(dfDomain, strFilterCol, strFilterValues)
  chrNamed <- unique(as.character(dfDomain[[strIDCol]])[bCounts])
  chrNamed <- chrNamed[!is.na(chrNamed) & nzchar(chrNamed)]

  dfNumerator <- stats::setNames(
    data.frame(chrNamed, stringsAsFactors = FALSE),
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

#' Which rows of a domain count towards a census figure?
#'
#' Three cases, and the difference between them is the whole configurability of
#' the counting metrics: no filter column counts every row; a filter column
#' with no values counts a row that *records* something; a filter column with
#' values counts a row that matches one of them.
#'
#' Missing is never a match. A row carried for some other reason, or one whose
#' completion flag was never filled in, must not read as a completion.
#'
#' @param dfDomain `data.frame` Domain being counted.
#' @param strFilterCol `character` or `NULL` Deciding column.
#' @param strFilterValues `character` or `NULL` Values that count, comma
#'   separated, compared without regard to case or surrounding space.
#'
#' @return `logical` of `nrow(dfDomain)`.
#'
#' @keywords internal
ParticipantCounts <- function(dfDomain, strFilterCol = NULL, strFilterValues = NULL) {
  if (is.null(strFilterCol)) {
    return(rep(TRUE, nrow(dfDomain)))
  }

  chrValue <- trimws(as.character(dfDomain[[strFilterCol]]))
  bRecorded <- !is.na(chrValue) & nzchar(chrValue)
  if (is.null(strFilterValues)) {
    return(bRecorded)
  }

  chrWanted <- toupper(trimws(unlist(strsplit(
    as.character(strFilterValues), ",",
    fixed = TRUE
  ))))
  chrWanted <- chrWanted[nzchar(chrWanted)]
  bRecorded & toupper(chrValue) %in% chrWanted
}
