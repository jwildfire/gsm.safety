#' The census figures, as the report presents them
#'
#' Reads the rows the census metrics published and lays them out in the order
#' and the sections the report workflow declares. It counts nothing: every
#' value on the page is the `Numerator` a metric published, beside the
#' `Denominator` that same metric published, under the labels that metric's own
#' definition carries. A figure the metrics did not publish is not here — see
#' [Report_CensusProvenance()], which names it as absent rather than leaving a
#' blank row on the page.
#'
#' @section Days published, years presented:
#'
#' The person-time metrics publish participant-days, because days are the
#' number actually summed and a metric publishing years would publish a figure
#' nothing in the pipeline can check against the domain it came from. The
#' report divides, and only for the metric IDs the workflow names under
#' `PersonTime`. The published days stay on the page in the provenance table,
#' so the division is checkable rather than taken on trust.
#'
#' @section Nothing flags:
#'
#' D0023.3 — the census metrics declare no threshold and publish an empty flag,
#' and there is no flag column here. A result that arrives carrying a flag is
#' refused rather than presented; see [RefuseFlaggedResults()].
#'
#' @param dfResults `data.frame` The reporting model's results —
#'   `Reporting_Results`, one row per metric per group, carrying `MetricID`,
#'   `Numerator` and `Denominator`.
#' @param dfMetrics `data.frame` The reporting model's metric definitions —
#'   `Reporting_Metrics`, carrying `ID`, `MetricID`, `Metric` and the
#'   `Numerator` and `Denominator` labels.
#' @param lSettings `list` The report workflow's settings: `Sections`, each a
#'   `Title` and the `Metrics` read out under it, and `PersonTime`, naming the
#'   metric IDs published in days along with `DaysPerYear` and the `Unit` to
#'   present them in.
#'
#' @return `data.frame`, one row per published figure, with columns `Section`,
#'   `ID`, `Figure`, `Value`, `Unit`, `Denominator` and `DenominatorLabel`.
#'
#' @examples
#' dfResults <- data.frame(
#'   MetricID = "Analysis_saf0004", GroupID = "AA-AA-000-0000",
#'   GroupLevel = "Study", Numerator = 13, Denominator = 762,
#'   Metric = 13 / 762, Score = 13, Flag = NA_integer_
#' )
#' dfMetrics <- data.frame(
#'   ID = "saf0004", MetricID = "Analysis_saf0004",
#'   Metric = "Deaths (Study)", Numerator = "Participants Who Died",
#'   Denominator = "Enrolled Participant"
#' )
#' Report_CensusFigures(
#'   dfResults, dfMetrics,
#'   lSettings = list(
#'     Sections = list(list(Title = "Population", Metrics = list("saf0004")))
#'   )
#' )
#'
#' @export
Report_CensusFigures <- function(dfResults, dfMetrics, lSettings) {
  RequireCensusInputs(dfResults, dfMetrics, lSettings)

  chrPersonTime <- CensusMetricIDs(lSettings$PersonTime$Metrics)
  nDaysPerYear <- lSettings$PersonTime$DaysPerYear
  if (is.null(nDaysPerYear)) nDaysPerYear <- 365.25
  gsm.core::stop_if(
    cnd = !(is.numeric(nDaysPerYear) && length(nDaysPerYear) == 1 &&
      is.finite(nDaysPerYear) && nDaysPerYear > 0),
    message = "lSettings$PersonTime$DaysPerYear is not a positive number"
  )
  strUnit <- lSettings$PersonTime$Unit
  if (is.null(strUnit)) strUnit <- "person-years"

  lRows <- list()
  for (lSection in lSettings$Sections) {
    strSection <- as.character(lSection$Title)[1]
    for (strID in CensusMetricIDs(lSection$Metrics)) {
      dfDef <- CensusDefinition(dfMetrics, strID)
      if (nrow(dfDef) == 0) next

      dfPublished <- CensusPublished(dfResults, as.character(dfDef$MetricID[1]))
      # Absent is not blank. A metric that published nothing gets no row here;
      # it is named in the provenance table instead.
      if (nrow(dfPublished) == 0) next
      RefuseFlaggedResults(dfPublished, strID)
      gsm.core::stop_if(
        cnd = nrow(dfPublished) > 1,
        message = paste0(
          "'", strID, "' published ", nrow(dfPublished), " rows; a census ",
          "figure is one number for one group. Coverage-style metrics belong ",
          "in lSettings$Coverage."
        )
      )

      bPersonTime <- strID %in% chrPersonTime
      lRows[[length(lRows) + 1]] <- data.frame(
        Section = strSection,
        ID = strID,
        Figure = CensusLabel(dfDef, "Metric"),
        Value = if (bPersonTime) {
          round(as.numeric(dfPublished$Numerator[1]) / nDaysPerYear, 1)
        } else {
          as.numeric(dfPublished$Numerator[1])
        },
        Unit = if (bPersonTime) strUnit else NA_character_,
        Denominator = as.numeric(dfPublished$Denominator[1]),
        DenominatorLabel = CensusLabel(dfDef, "Denominator"),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(lRows) == 0) {
    return(data.frame(
      Section = character(0), ID = character(0), Figure = character(0),
      Value = numeric(0), Unit = character(0), Denominator = numeric(0),
      DenominatorLabel = character(0), stringsAsFactors = FALSE
    ))
  }
  dfFigures <- do.call(rbind, lRows)
  rownames(dfFigures) <- NULL
  dfFigures
}
