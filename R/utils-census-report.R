#' Shared internals of the census report
#'
#' The census report reads. Every helper in this file resolves a metric ID to
#' the row that metric published and hands it on unchanged; none of them counts
#' anything, and none of them takes a study domain as an argument, so none of
#' them could. That is the property step three of the SafetyCensus rebuild
#' exists to preserve — a number is validated once, in its metric, and read
#' everywhere else.
#'
#' @name utils-census-report
#' @keywords internal
NULL

#' Metric IDs from a settings entry
#'
#' The workflow's settings are read from YAML, where a list of one and a list
#' of many arrive in different shapes and an omitted key arrives as `NULL`.
#'
#' @param x Settings value naming metric IDs.
#'
#' @return `character`, empty when nothing is named.
#'
#' @keywords internal
CensusMetricIDs <- function(x) {
  if (is.null(x)) {
    return(character(0))
  }
  chrIDs <- as.character(unlist(x, use.names = FALSE))
  chrIDs[!is.na(chrIDs) & nzchar(chrIDs)]
}

#' Guard the inputs every census report helper shares
#'
#' @param dfResults `data.frame` The metric results.
#' @param dfMetrics `data.frame` The metric definitions.
#' @param lSettings `list` The report's settings.
#'
#' @return `NULL`, invisibly. Stops when an input cannot be read.
#'
#' @keywords internal
RequireCensusInputs <- function(dfResults, dfMetrics, lSettings) {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfResults),
    message = "dfResults is not a data.frame"
  )
  gsm.core::stop_if(
    cnd = !is.data.frame(dfMetrics),
    message = "dfMetrics is not a data.frame"
  )
  gsm.core::stop_if(
    cnd = !is.list(lSettings),
    message = "lSettings is not a list"
  )
  .RequireColumns(dfResults, c("MetricID", "Numerator", "Denominator"), "dfResults")
  .RequireColumns(dfMetrics, c("ID", "MetricID", "Metric"), "dfMetrics")
  invisible(NULL)
}

#' Refuse to present a flagged result as a census figure
#'
#' D0023.3 — no census number raises anything, and the metrics enforce that by
#' declaring no threshold and calling [Flag_None()]. A result that arrives
#' carrying a flag did not come from a census metric, and presenting it on a
#' page that shows no flags would hide a signal rather than describe a study.
#' It stops.
#'
#' @param dfResults `data.frame` Rows about to be presented.
#' @param chrIDs `character` Metric IDs they belong to, for the message.
#'
#' @return `NULL`, invisibly.
#'
#' @keywords internal
RefuseFlaggedResults <- function(dfResults, chrIDs = character(0)) {
  if (!("Flag" %in% names(dfResults)) || nrow(dfResults) == 0) {
    return(invisible(NULL))
  }
  bFlagged <- !is.na(dfResults$Flag)
  gsm.core::stop_if(
    cnd = any(bFlagged),
    message = paste0(
      "The census report presents no flag, so it will not present a result ",
      "that carries one: ", sum(bFlagged), " of ", nrow(dfResults),
      " rows arrived flagged",
      if (length(chrIDs)) paste0(" (", paste(unique(chrIDs), collapse = ", "), ")") else "",
      ". A census metric declares no threshold and publishes an empty flag."
    )
  )
  invisible(NULL)
}

#' The definition row for one metric ID, or nothing
#'
#' @param dfMetrics `data.frame` The metric definitions.
#' @param strID `character` A metric's short ID, e.g. `"saf0004"`.
#'
#' @return `data.frame` of zero or one row.
#'
#' @keywords internal
CensusDefinition <- function(dfMetrics, strID) {
  dfDef <- dfMetrics[!is.na(dfMetrics$ID) & dfMetrics$ID == strID, , drop = FALSE]
  gsm.core::stop_if(
    cnd = nrow(dfDef) > 1,
    message = paste0(
      "dfMetrics defines '", strID, "' ", nrow(dfDef), " times; a census ",
      "figure has exactly one definition"
    )
  )
  dfDef
}

#' The rows one metric published, in the order it published them
#'
#' @param dfResults `data.frame` The metric results.
#' @param strMetricID `character` The reporting model's metric key, e.g.
#'   `"Analysis_saf0004"`.
#'
#' @return `data.frame` of the published rows; zero rows when the metric
#'   published none.
#'
#' @keywords internal
CensusPublished <- function(dfResults, strMetricID) {
  dfResults[
    !is.na(dfResults$MetricID) & dfResults$MetricID == strMetricID, ,
    drop = FALSE
  ]
}

#' A label from a metric definition, or an empty string
#'
#' @param dfDef `data.frame` One definition row.
#' @param strCol `character` Column to read.
#'
#' @return `character(1)`.
#'
#' @keywords internal
CensusLabel <- function(dfDef, strCol) {
  if (nrow(dfDef) == 0 || !(strCol %in% names(dfDef))) {
    return("")
  }
  strLabel <- as.character(dfDef[[strCol]][1])
  if (is.na(strLabel)) "" else strLabel
}
