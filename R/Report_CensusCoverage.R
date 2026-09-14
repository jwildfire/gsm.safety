#' The data-coverage rows, as the report presents them
#'
#' Reads the rows a data-coverage metric published — one per visit, the
#' participants with a result against the participants expected — and hands
#' them on in the order they were published. Like every other helper behind the
#' census report it counts nothing; both numbers in each row come from the
#' metric.
#'
#' @section Absent, not empty:
#'
#' The thirteenth census metric did not land, and the reasons are recorded on
#' [gsm.safety#58](https://github.com/jwildfire/gsm.safety/issues/58): under
#' the standard mapping the lab domain carries no visit column, and the
#' expected count needs a per-visit study day no domain supplies. A report
#' whose settings name no coverage metric, or whose coverage metric published
#' nothing, gets **no coverage section at all** — [Report_SafetyCensus()] drops
#' the heading with the table. An empty coverage table would read as a study
#' with no data rather than as a report with no metric, which is the exact
#' confusion a coverage figure exists to prevent.
#'
#' @section The visit order is the metric's, not the label's:
#'
#' Rows are presented in the order the metric published them and are never
#' sorted by visit label. Sorting by label is what made week twelve come before
#' week two in the function this report replaces.
#'
#' @inheritParams Report_CensusFigures
#'
#' @return `data.frame`, one row per published coverage row, with columns `ID`,
#'   `Figure`, `Group`, `Participants` and `Expected`. Zero rows when no
#'   coverage figure was published.
#'
#' @examples
#' # No coverage metric is named, so there is nothing to present.
#' Report_CensusCoverage(
#'   dfResults = data.frame(
#'     MetricID = character(0), Numerator = numeric(0), Denominator = numeric(0)
#'   ),
#'   dfMetrics = data.frame(
#'     ID = character(0), MetricID = character(0), Metric = character(0)
#'   ),
#'   lSettings = list(Coverage = list(Metrics = list()))
#' )
#'
#' @export
Report_CensusCoverage <- function(dfResults, dfMetrics, lSettings) {
  RequireCensusInputs(dfResults, dfMetrics, lSettings)

  dfEmpty <- data.frame(
    ID = character(0), Figure = character(0), Group = character(0),
    Participants = numeric(0), Expected = numeric(0),
    stringsAsFactors = FALSE
  )

  chrIDs <- CensusMetricIDs(lSettings$Coverage$Metrics)
  if (length(chrIDs) == 0) {
    return(dfEmpty)
  }

  lRows <- list()
  for (strID in chrIDs) {
    dfDef <- CensusDefinition(dfMetrics, strID)
    if (nrow(dfDef) == 0) next

    dfPublished <- CensusPublished(dfResults, as.character(dfDef$MetricID[1]))
    if (nrow(dfPublished) == 0) next
    RefuseFlaggedResults(dfPublished, strID)

    strGroup <- if ("GroupID" %in% names(dfPublished)) {
      as.character(dfPublished$GroupID)
    } else {
      rep(NA_character_, nrow(dfPublished))
    }
    lRows[[length(lRows) + 1]] <- data.frame(
      ID = strID,
      Figure = CensusLabel(dfDef, "Metric"),
      Group = strGroup,
      Participants = as.numeric(dfPublished$Numerator),
      Expected = as.numeric(dfPublished$Denominator),
      stringsAsFactors = FALSE
    )
  }

  if (length(lRows) == 0) {
    return(dfEmpty)
  }
  dfCoverage <- do.call(rbind, lRows)
  rownames(dfCoverage) <- NULL
  dfCoverage
}
