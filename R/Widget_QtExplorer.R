#' QT Safety Explorer Widget
#'
#' A widget that renders the safety.viz QT/QTc safety explorer across three
#' linked views: central tendency (mean change from baseline and
#' placebo-corrected change with confidence intervals, against the ICH E14
#' 10 ms threshold of regulatory concern), an outlier scatter of absolute
#' values and changes against the 450/480/500 ms and 30/60 ms category
#' boundaries, and a categorical summary of participants crossing them.
#'
#' @param dfResults `data.frame` Long-format ECG results, one record per
#'   measurement. Column names are supplied by `lSettings`; the defaults expect
#'   the ADaM ADEG standard (`TEST`/`STRESN`/`BASE`/`ARM`, plus
#'   `VISIT`/`VISITNUM`/`ABLFL` — see `inst/schema/qt-explorer.json`), so data
#'   using those names needs no settings at all. The `measures` setting selects
#'   which `TEST` values are charted and `qtc_measures` marks which of them are
#'   QTc intervals.
#' @param lSettings `list` safety.viz qt-explorer settings overrides; merged
#'   onto the module's `DEFAULT_SETTINGS` client-side, so only overrides are
#'   needed. Set `placebo_arm` to enable the placebo-corrected (ΔΔ) view.
#' @param width `character` Width of the widget as a CSS unit. Default: `NULL`.
#' @param height `character` Height of the widget as a CSS unit. Default:
#'   `NULL`.
#' @param elementId `character` ID of the widget's HTML element. Default:
#'   `NULL`.
#' @param bDebug `logical` Print debug messages in the browser console?
#'   Default: `FALSE`.
#'
#' @examples
#' dfResults <- ExampleData("adeg")
#'
#' # The bundled ADEG data uses the default column names, so the chart
#' # initializes with no settings.
#' Widget_QtExplorer(dfResults)
#'
#' # Name the placebo arm to add the placebo-corrected change (ΔΔ) view.
#' Widget_QtExplorer(
#'   dfResults,
#'   lSettings = list(
#'     placebo_arm = "Placebo",
#'     filters = list(
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race"),
#'       list(value_col = "SITE", label = "Site")
#'     )
#'   )
#' )
#'
#' @export
Widget_QtExplorer <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "qt-explorer",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_QtExplorer",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
