#' Results Over Time Widget
#'
#' A widget that renders the safety.viz results-over-time chart: the
#' distribution of a long-format safety measure (labs, vitals) across visits,
#' with optional filters and group-by columns that split each visit into
#' side-by-side box plots.
#'
#' @param dfResults `data.frame` Long-format results data, one record per
#'   participant per visit per measure. Column names are supplied by
#'   `lSettings`; the defaults expect
#'   `TEST`/`STRESN`/`VISIT`/`VISITNUM`/`USUBJID`/`STRESU` (see
#'   `inst/schema/results-over-time.json`).
#' @param lSettings `list` safety.viz results-over-time settings overrides;
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
#' Widget_ResultsOverTime(
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
#'       list(value_col = "SITEID", label = "Site")
#'     ),
#'     group_by = "ARM"
#'   )
#' )
#'
#' @export
Widget_ResultsOverTime <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "results-over-time",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_ResultsOverTime",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId
  )
}
