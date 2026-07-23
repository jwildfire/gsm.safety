#' Shift Plot Widget
#'
#' A widget that renders the safety.viz shift plot: a baseline-versus-comparison
#' scatter that pairs each participant's baseline-visit value against their
#' comparison-visit value for a selected measure, with optional filters,
#' summary-statistic controls, and a participant-level listing.
#'
#' @param dfResults `data.frame` Long-format results data, one record per
#'   participant per visit per measure. Column names are supplied by
#'   `lSettings`; the defaults expect
#'   `TEST`/`STRESN`/`VISIT`/`VISITNUM`/`USUBJID`/`STRESU` (see
#'   `inst/schema/shift-plot.json`).
#' @param lSettings `list` safety.viz shift-plot settings overrides; merged
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
#' Widget_ShiftPlot(
#'   dfResults,
#'   lSettings = list(
#'     filters = list(
#'       list(value_col = "SITEID", label = "Site ID"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "ARM", label = "Treatment Group")
#'     ),
#'     baseline_visits = list("Baseline"),
#'     comparison_visits = list("Week 26")
#'   )
#' )
#'
#' @export
Widget_ShiftPlot <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "shift-plot",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_ShiftPlot",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
