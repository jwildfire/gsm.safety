#' Hepatic ALT Waterfall Widget
#'
#' A widget that renders the safety.viz modified ALT waterfall (Amirzadegan et
#' al., *Drug Safety* 2025;48(5):443-453, Figure 5) for trials that enrol
#' participants with abnormal baseline liver tests: one floating bar per
#' participant from their baseline to their maximum on-treatment value in
#' absolute units, ranked by baseline so the two arms' highest baselines meet
#' at the seam, with new-onset jaundice overriding the arm colour and a
#' box-and-whisker summary flanking each arm. The renderer is marked a
#' prototype upstream pending open clinical judgement calls.
#'
#' @param dfResults `data.frame` Long-format lab results, one record per
#'   measurement, carrying at least the waterfall measure and total bilirubin
#'   (for the jaundice overlay and the baseline-bilirubin cohort rule). Column
#'   names are supplied by `lSettings` (see `inst/schema/hep-waterfall.json`);
#'   `measure_values` maps the liver-measure keys to the data's `TEST` values,
#'   and naming `placebo_arm`/`active_arms` avoids relying on the arm-name
#'   auto-detect.
#' @param lSettings `list` safety.viz hep-waterfall settings overrides; merged
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
#' # The bundled synthetic abnormal-baseline cohort; the pilot trial data
#' # cannot form this figure (see the safety.viz demo's data note).
#' dfResults <- ExampleData("adbds_abnbl")
#'
#' Widget_HepWaterfall(
#'   dfResults,
#'   lSettings = list(
#'     studyday_col = "VISITNUM",
#'     measure_values = list(
#'       ALT = "Alanine Aminotransferase",
#'       AST = "Aspartate Aminotransferase",
#'       TB = "Bilirubin",
#'       ALP = "Alkaline Phosphatase"
#'     ),
#'     arm_col = "ARM",
#'     placebo_arm = "ABL: Placebo",
#'     active_arms = list("ABL: Study Drug")
#'   )
#' )
#'
#' @export
Widget_HepWaterfall <- function(
    dfResults,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "hep-waterfall",
    bDebug = bDebug
  )

  htmlwidgets::createWidget(
    name = "Widget_HepWaterfall",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}
