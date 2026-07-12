#' Delta-Delta Widget
#'
#' A widget that renders the safety.viz delta-delta plot: change from baseline
#' in one measure versus change from baseline in another, one point per
#' participant, with baseline/comparison visit selectors, optional filters, and
#' an optional linear regression line.
#'
#' @param dfResults `data.frame` Long-format results data, one record per
#'   measurement at a visit. Column names are supplied by `lSettings`; the
#'   defaults expect `TEST`/`STRESN`/`USUBJID`/`VISIT`/`VISITNUM` (see
#'   `inst/schema/delta-delta.json`).
#' @param lSettings `list` safety.viz delta-delta settings overrides; merged
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
#' Widget_DeltaDelta(
#'   dfResults,
#'   lSettings = list(
#'     filters = list(
#'       list(value_col = "SITE", label = "Site"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "USUBJID", label = "Participant ID")
#'     ),
#'     measure_x = "Alanine Aminotransferase",
#'     measure_y = "Aspartate Aminotransferase",
#'     add_regression_line = TRUE
#'   )
#' )
#'
#' @export
Widget_DeltaDelta <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "delta-delta",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_DeltaDelta",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId
  )
}
