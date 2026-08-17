#' Assemble a participant-level `analyticsInput` frame
#'
#' The gsm analytics contract is `analyticsInput`
#' (`SubjectID`, `GroupID`, `GroupLevel`, `Numerator`, `Denominator`,
#' `Metric`) in, `analyticsSummary` out. gsm.safety's metrics are
#' participant-level — `GroupLevel: Subject`, with `GroupID` equal to
#' `SubjectID`, following the `pat0015.yaml` precedent in gsm.kri — and each
#' one scores a participant with an ordinal *tier* rather than a rate.
#'
#' Every metric therefore emits one row per **assessed** participant with
#' `Numerator` = the tier and `Denominator` = 1, so `gsm.core::Transform_Rate()`
#' carries the tier through to `Metric` unchanged and
#' `gsm.core::Analyze_Identity()` copies it to `Score`. A participant with no
#' assessable data gets no row at all: "not assessed" is absence, never a
#' reassuring zero. The row count is the metric's own coverage denominator.
#'
#' Evidence columns (peak values, counts, the terms behind a flag) are carried
#' through on this frame. `Transform_Rate()` summarises them away, but the
#' unsummarised `Analysis_Input` is saved beside every other step's output, so
#' the numbers behind a flag stay one file away from the flag itself.
#'
#' @param dfEvidence `data.frame` One row per assessed participant, carrying at
#'   least the participant ID column and a `Numerator` column holding the tier.
#' @param strIDCol `character` Name of the participant ID column in
#'   `dfEvidence`. Default: `"subjid"`.
#' @param strGroupLevel `character` Group level to record. Default: `"Subject"`.
#'
#' @return `data.frame` with `SubjectID`, `GroupID`, `GroupLevel`, `Numerator`,
#'   `Denominator`, `Metric`, followed by every other column of `dfEvidence`.
#'
#' @keywords internal
MakeParticipantInput <- function(
    dfEvidence,
    strIDCol = "subjid",
    strGroupLevel = "Subject") {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfEvidence),
    message = "dfEvidence is not a data.frame"
  )
  gsm.core::stop_if(
    cnd = !(strIDCol %in% names(dfEvidence)),
    message = paste0("strIDCol '", strIDCol, "' not found in dfEvidence")
  )
  gsm.core::stop_if(
    cnd = !("Numerator" %in% names(dfEvidence)),
    message = "dfEvidence has no `Numerator` column"
  )

  chrID <- as.character(dfEvidence[[strIDCol]])
  dfExtra <- dfEvidence[, setdiff(names(dfEvidence), c(strIDCol, "Numerator")), drop = FALSE]

  dfInput <- data.frame(
    SubjectID = chrID,
    GroupID = chrID,
    # A zero-row frame must stay zero-row: recycling a length-1 constant into
    # it is an error, not an empty column.
    GroupLevel = rep(strGroupLevel, length(chrID)),
    Numerator = as.numeric(dfEvidence$Numerator),
    Denominator = rep(1, length(chrID)),
    stringsAsFactors = FALSE
  )
  dfInput$Metric <- dfInput$Numerator / dfInput$Denominator

  if (ncol(dfExtra) > 0) {
    dfInput <- cbind(dfInput, dfExtra)
  }
  rownames(dfInput) <- NULL
  dfInput
}

#' Worst (maximum) value of `strValueCol` per participant, NA-safe
#'
#' Returns a named numeric vector keyed by participant ID. Participants whose
#' every value is missing or non-finite are dropped rather than returned as
#' `-Inf`, so "no usable result" never reads as a low result.
#'
#' @param df `data.frame` Long-format records.
#' @param strIDCol `character` Participant ID column.
#' @param strValueCol `character` Numeric column to reduce.
#'
#' @return Named `numeric`, one element per participant with at least one
#'   finite value.
#'
#' @keywords internal
PeakByParticipant <- function(df, strIDCol, strValueCol) {
  if (nrow(df) == 0) {
    return(stats::setNames(numeric(0), character(0)))
  }
  nValue <- suppressWarnings(as.numeric(df[[strValueCol]]))
  bKeep <- is.finite(nValue)
  if (!any(bKeep)) {
    return(stats::setNames(numeric(0), character(0)))
  }
  vPeak <- tapply(nValue[bKeep], as.character(df[[strIDCol]][bKeep]), max)
  vPeak[is.finite(vPeak)]
}

#' Align a named per-participant vector to a participant ID vector
#'
#' @param vNamed Named `numeric` as returned by [PeakByParticipant()].
#' @param chrIDs `character` Participant IDs to align to.
#'
#' @return `numeric` of `length(chrIDs)`, `NA` where the participant is absent.
#'
#' @keywords internal
AlignToParticipants <- function(vNamed, chrIDs) {
  out <- as.numeric(vNamed[chrIDs])
  out
}

#' Highest tier reached, given ordered tier conditions
#'
#' Each element of `lConditions` is a logical vector over the same participants,
#' named by the tier it confers. The result is the maximum tier whose condition
#' holds, and `0` where none does.
#'
#' @param lConditions Named `list` of logical vectors; names are the tier
#'   numbers as character (`"1"`, `"2"`, `"3"`).
#' @param nLength `integer` Number of participants.
#'
#' @return `numeric` tier per participant.
#'
#' @keywords internal
HighestTier <- function(lConditions, nLength) {
  nTier <- rep(0, nLength)
  for (strTier in names(lConditions)) {
    bHit <- lConditions[[strTier]]
    bHit[is.na(bHit)] <- FALSE
    nTier[bHit] <- pmax(nTier[bHit], as.numeric(strTier))
  }
  nTier
}
