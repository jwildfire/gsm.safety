# Guards shared by the census metrics' input steps.
#
# The framework does not do this for us. `gsm.core::CheckSpec()` errors on a
# missing data.frame but only *logs a warning* on a declared column that is
# missing, so a metric that trusted its spec would read a missing column as an
# absent value and publish a zero. Declaring the columns in the yaml is
# necessary; stopping when one of them is gone has to happen here.
#
# One copy of these checks, called by every census input step, is deliberate:
# twelve hand-written guards are twelve chances to write one of them wrong.

#' Stop unless the object is a data.frame
#'
#' @param df Object to check.
#' @param strName `character` Name the reader has to act on — the mapped domain
#'   the metric declares, not the parameter it arrived in.
#'
#' @return `NULL`, invisibly. Called for the error.
#'
#' @keywords internal
.RequireFrame <- function(df, strName) {
  gsm.core::stop_if(
    cnd = !is.data.frame(df),
    message = paste0(
      strName, " is not a data.frame: this study supplies no such domain, ",
      "so the figure is absent rather than zero"
    )
  )
  invisible(NULL)
}

#' Stop unless every named column is present
#'
#' @param df `data.frame` to check.
#' @param chrCols `character` Columns that must be present. `NULL` entries are
#'   dropped, so an optional column can be passed straight through.
#' @param strName `character` Domain name for the message.
#'
#' @return `NULL`, invisibly. Called for the error.
#'
#' @keywords internal
.RequireColumns <- function(df, chrCols, strName) {
  chrCols <- unlist(chrCols)
  for (strCol in chrCols) {
    gsm.core::stop_if(
      cnd = !(strCol %in% names(df)),
      message = paste0("Column '", strCol, "' not found in ", strName)
    )
  }
  invisible(NULL)
}

#' One row per participant
#'
#' @param df `data.frame` to reduce.
#' @param strIDCol `character` Participant ID column.
#'
#' @return `df` with later rows for an already-seen participant dropped.
#'
#' @keywords internal
.OnePerParticipant <- function(df, strIDCol) {
  df[!duplicated(as.character(df[[strIDCol]])), , drop = FALSE]
}

#' The empty `analyticsInput` frame
#'
#' What a census metric publishes when it has measured nothing: no row at all,
#' rather than a row reading zero.
#'
#' @return `data.frame` with the `analyticsInput` columns and no rows.
#'
#' @keywords internal
.NoFigure <- function() {
  data.frame(
    SubjectID = character(0),
    GroupID = character(0),
    GroupLevel = character(0),
    Numerator = numeric(0),
    Denominator = numeric(0),
    Metric = numeric(0),
    stringsAsFactors = FALSE
  )
}

#' Is the enrolled population empty?
#'
#' No denominator is not a denominator of zero. A study whose subject domain
#' has no rows has no population to count against, so nothing is published.
#'
#' @param dfSubjects `data.frame` Enrolled population.
#'
#' @return `logical(1)`, with a warning logged when `TRUE`.
#'
#' @keywords internal
.NoEnrolledPopulation <- function(dfSubjects) {
  if (nrow(dfSubjects) > 0) {
    return(FALSE)
  }
  gsm.core::LogMessage(
    level = "warn",
    message = paste0(
      "The enrolled population is empty, so no census figure is published. ",
      "A study with nobody enrolled has no denominator, which is not the ",
      "same as a denominator of zero."
    )
  )
  TRUE
}

#' A short, readable list of participant IDs for a warning
#'
#' @param chrIDs `character` Participant IDs.
#' @param nMax `integer` How many to name before summarising the rest.
#'
#' @return `character(1)`.
#'
#' @keywords internal
.NameParticipants <- function(chrIDs, nMax = 10L) {
  chrIDs <- unique(as.character(chrIDs))
  if (length(chrIDs) <= nMax) {
    return(paste(chrIDs, collapse = ", "))
  }
  paste0(
    paste(chrIDs[seq_len(nMax)], collapse = ", "),
    " and ", length(chrIDs) - nMax, " more"
  )
}
