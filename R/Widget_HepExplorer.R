#' Hepatic Safety Explorer (eDISH) Widget
#'
#' A widget that renders the safety.viz hepatic safety explorer: an eDISH
#' scatter plot of peak liver measures (ALT vs. total bilirubin, as multiples
#' of the upper limit of normal) with Hy's Law quadrants, participant
#' drill-down to a standardized-values-by-study-day view, and a linked
#' measure table.
#'
#' @param dfResults `data.frame` Long-format results data, one record per
#'   measurement. Column names are supplied by `lSettings`; the defaults
#'   expect `TEST`/`STRESN`/`USUBJID`/`STNRHI` (see
#'   `inst/schema/hep-explorer.json`). The `measure_values` setting maps the
#'   ALT/AST/TB/ALP keys onto the dataset's measure names.
#' @param lSettings `list` safety.viz hep-explorer settings overrides; merged
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
#' Widget_HepExplorer(
#'   dfResults,
#'   lSettings = list(
#'     studyday_col = "VISITNUM",
#'     visit_col = "VISIT",
#'     visitn_col = "VISITNUM",
#'     measure_values = list(
#'       ALT = "Alanine Aminotransferase",
#'       AST = "Aspartate Aminotransferase",
#'       TB = "Bilirubin",
#'       ALP = "Alkaline Phosphatase"
#'     ),
#'     filters = list(
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "ARM", label = "Treatment Group")
#'     ),
#'     groups = list(
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "SEX", label = "Sex")
#'     )
#'   )
#' )
#'
#' @export
Widget_HepExplorer <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "hep-explorer",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_HepExplorer",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
