#' Histogram Widget
#'
#' A widget that renders the safety.viz histogram: the distribution of
#' long-format safety results (labs, vitals) for a selected measure, with
#' optional filters, group-by small multiples, normal-range annotations, and
#' distribution comparison tests.
#'
#' @param dfResults `data.frame` Long-format results data, one record per
#'   measurement. Column names are supplied by `lSettings`; the defaults
#'   expect `TEST`/`STRESN`/`USUBJID`/`STRESU`/`STNRLO`/`STNRHI` (see
#'   `inst/schema/histogram.json`).
#' @param lSettings `list` safety.viz histogram settings overrides; merged
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
#' Widget_Histogram(
#'   dfResults,
#'   lSettings = list(
#'     filters = list(
#'       list(value_col = "SITEID", label = "Site ID"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "USUBJID", label = "Participant ID")
#'     ),
#'     groups = list(
#'       list(value_col = "SITE", label = "Site"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "ARM", label = "Treatment Group")
#'     ),
#'     display_normal_range = TRUE,
#'     annotate_bin_boundaries = TRUE,
#'     test_normality = TRUE,
#'     group_by = "ARM",
#'     compare_distributions = TRUE
#'   )
#' )
#'
#' @export
Widget_Histogram <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "histogram",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_Histogram",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
