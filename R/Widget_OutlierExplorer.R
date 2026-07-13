#' Outlier Explorer Widget
#'
#' A widget that renders the safety.viz outlier explorer: one line per
#' participant across a measurement or time axis for a selected measure, with
#' optional filters, color-by groups, normal-range annotations, and a detail
#' listing for inspecting flagged outliers.
#'
#' @param dfResults `data.frame` Long-format results data, one record per
#'   measurement. Column names are supplied by `lSettings`; the defaults
#'   expect `TEST`/`STRESN`/`USUBJID`/`STRESU`/`STNRLO`/`STNRHI` (see
#'   `inst/schema/outlier-explorer.json`).
#' @param lSettings `list` safety.viz outlier-explorer settings overrides;
#'   merged onto the module's `DEFAULT_SETTINGS` client-side, so only overrides
#'   are needed.
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
#' Widget_OutlierExplorer(
#'   dfResults,
#'   lSettings = list(
#'     filters = list(
#'       list(value_col = "SITEID", label = "Site ID"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "ARM", label = "Treatment Group")
#'     ),
#'     groups = list(
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "SITE", label = "Site")
#'     ),
#'     details = list(
#'       list(value_col = "USUBJID", label = "Participant ID"),
#'       list(value_col = "STRESN", label = "Result"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "ARM", label = "Treatment Group")
#'     )
#'   )
#' )
#'
#' @export
Widget_OutlierExplorer <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "outlier-explorer",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_OutlierExplorer",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
