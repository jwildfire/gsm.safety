#' What each census metric published, verbatim
#'
#' Every metric the report was configured to read, in the order it reads them,
#' with the numbers exactly as published — participant-days in days, counts as
#' counts — and, where a metric published nothing, a line saying so.
#'
#' This table is what makes the report auditable. The figures table presents;
#' this one records. A reader who wants to check that the exposure figure was
#' divided rather than recounted can read the days here and the years there,
#' and a metric that stopped because a study supplies no such domain is named
#' rather than silently missing.
#'
#' @section Three states, kept apart:
#'
#' `Status` distinguishes the three states the census metrics are built to keep
#' apart. **published** is a figure, and a published `0` is a measurement.
#' **no row published** is a metric that ran and measured nothing — the domain
#' was absent or empty, and it stopped rather than reporting a zero.
#' **not run for this study** is a metric the report was told to read that this
#' study's reporting model does not carry at all: the study never ran it. On
#' any study with no ECG domain that is `saf0011`, because a batch that
#' includes it stops on the missing domain rather than publishing a zero.
#'
#' @inheritParams Report_CensusFigures
#'
#' @return `data.frame`, one row per metric named in `lSettings`, with columns
#'   `ID`, `Figure`, `Numerator`, `Denominator` and `Status`.
#'
#' @examples
#' Report_CensusProvenance(
#'   dfResults = data.frame(
#'     MetricID = "Analysis_saf0008", GroupID = "AA-AA-000-0000",
#'     Numerator = 26754, Denominator = 762, Flag = NA_integer_
#'   ),
#'   dfMetrics = data.frame(
#'     ID = c("saf0008", "saf0011"),
#'     MetricID = c("Analysis_saf0008", "Analysis_saf0011"),
#'     Metric = c(
#'       "Participant-Days on Study (Study)", "Participants With an ECG (Study)"
#'     )
#'   ),
#'   lSettings = list(
#'     Sections = list(
#'       list(Title = "Exposure", Metrics = list("saf0008", "saf0011"))
#'     )
#'   )
#' )
#'
#' @export
Report_CensusProvenance <- function(dfResults, dfMetrics, lSettings) {
  RequireCensusInputs(dfResults, dfMetrics, lSettings)

  chrIDs <- unique(c(
    unlist(lapply(lSettings$Sections, function(l) CensusMetricIDs(l$Metrics))),
    CensusMetricIDs(lSettings$Coverage$Metrics)
  ))

  lRows <- lapply(chrIDs, function(strID) {
    dfDef <- CensusDefinition(dfMetrics, strID)
    if (nrow(dfDef) == 0) {
      return(data.frame(
        ID = strID, Figure = NA_character_, Numerator = NA_real_,
        Denominator = NA_real_, Status = "not run for this study",
        stringsAsFactors = FALSE
      ))
    }

    dfPublished <- CensusPublished(dfResults, as.character(dfDef$MetricID[1]))
    if (nrow(dfPublished) == 0) {
      return(data.frame(
        ID = strID, Figure = CensusLabel(dfDef, "Metric"),
        Numerator = NA_real_, Denominator = NA_real_,
        Status = "no row published", stringsAsFactors = FALSE
      ))
    }
    RefuseFlaggedResults(dfPublished, strID)

    data.frame(
      ID = strID,
      Figure = CensusLabel(dfDef, "Metric"),
      Numerator = as.numeric(dfPublished$Numerator),
      Denominator = as.numeric(dfPublished$Denominator),
      Status = "published",
      stringsAsFactors = FALSE
    )
  })

  if (length(lRows) == 0) {
    return(data.frame(
      ID = character(0), Figure = character(0), Numerator = numeric(0),
      Denominator = numeric(0), Status = character(0), stringsAsFactors = FALSE
    ))
  }
  dfProvenance <- do.call(rbind, lRows)
  rownames(dfProvenance) <- NULL
  dfProvenance
}
