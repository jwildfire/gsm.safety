#' Nephrotoxicity Explorer Widget
#'
#' A widget that renders the safety.viz KDIGO nephrotoxicity explorer: one
#' point per participant at their maximum post-baseline fold change in serum
#' creatinine against their maximum absolute change, over the L-shaped KDIGO
#' acute-kidney-injury stage zones, with a stage summary table beside the
#' chart. Participants meeting the KDIGO >= 4.0 mg/dL Stage 3 criterion are
#' drawn as a distinct triangular mark rather than a zone. The renderer is
#' marked Experimental upstream pending clinical confirmation of the staging
#' ladder.
#'
#' @param dfResults `data.frame` Long-format lab results, one record per
#'   measurement. Column names are supplied by `lSettings`; the defaults
#'   expect the BDS standard (`USUBJID`/`TEST`/`STRESN`/`STRESU`, plus
#'   `VISIT`/`VISITNUM` — see `inst/schema/nep-explorer.json`), so data using
#'   those names needs no settings at all. Serum creatinine is selected by
#'   `measure_values$CREAT` (default `"Creatinine"`).
#' @param lSettings `list` safety.viz nep-explorer settings overrides; merged
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
#' dfResults <- ExampleData("adbds")
#'
#' # The bundled BDS data uses the default column names, so the chart
#' # initializes with no settings. The synthetic `AKI-*` cohort supplies the
#' # staged participants; the pilot population alone stays in the no-stage box.
#' Widget_NepExplorer(dfResults)
#'
#' # Add cohort filters.
#' Widget_NepExplorer(
#'   dfResults,
#'   lSettings = list(
#'     filters = list(
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race")
#'     )
#'   )
#' )
#'
#' @export
Widget_NepExplorer <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "nep-explorer",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_NepExplorer",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
