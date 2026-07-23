#' Adverse Event Explorer Widget
#'
#' A widget that renders the safety.viz adverse-event explorer: a
#' System-Organ-Class / preferred-term prevalence table with per-arm rates and
#' a between-arm difference plot, expandable to the events behind any row and
#' filterable down to a participant listing.
#'
#' @param dfResults `data.frame` Adverse-event data, one record per event, plus
#'   one placeholder row per participant with no adverse events so the
#'   population denominator covers the whole safety population. Placeholder
#'   rows carry a blank System Organ Class and never render as events. Column
#'   names are supplied by `lSettings`; the defaults expect the ADaM ADAE
#'   standard (`USUBJID`/`AEBODSYS`/`AEDECOD`/`ARM` — see
#'   `inst/schema/ae-explorer.json`), so data using those names needs no
#'   settings at all.
#' @param lSettings `list` safety.viz ae-explorer settings overrides; merged
#'   onto the module's `DEFAULT_SETTINGS` client-side, so only overrides are
#'   needed.
#' @param width `character` Width of the widget as a CSS unit. Default: `NULL`.
#' @param height `character` Height of the widget as a CSS unit. Default:
#'   `NULL`.
#' @param elementId `character` ID of the widget's HTML element. Default:
#'   `NULL`.
#' @param bDebug `logical` Print debug messages in the browser console?
#'   Default: `FALSE`.
#'
#' @examples
#' dfResults <- ExampleData("adae")
#'
#' # The bundled ADAE data uses the default column names, so the chart
#' # initializes with no settings.
#' Widget_AeExplorer(dfResults)
#'
#' # Add filters and a severity drill-down.
#' Widget_AeExplorer(
#'   dfResults,
#'   lSettings = list(
#'     filters = list(
#'       list(value_col = "AESEV", label = "Severity"),
#'       list(value_col = "AESER", label = "Serious")
#'     ),
#'     details = list(
#'       list(value_col = "AETERM", label = "Reported Term"),
#'       list(value_col = "AESEV", label = "Severity"),
#'       list(value_col = "ASTDY", label = "Start Day")
#'     )
#'   )
#' )
#'
#' @export
Widget_AeExplorer <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "ae-explorer",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_AeExplorer",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
