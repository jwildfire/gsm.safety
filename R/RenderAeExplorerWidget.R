#' Save an initialized AE Explorer widget as standalone HTML
#'
#' @param lInitialized A list returned by [safetyCharts::init_aeExplorer()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when absent.
#'
#' @return A list with the report path and htmlwidget.
#' @export
RenderAeExplorerWidget <- function(lInitialized,
                                   strOutputDir = getwd(),
                                   strOutputFile = "ae_explorer") {
  RenderSafetyChartsWidget(
    lInitialized = lInitialized,
    strWidgetName = "aeExplorer",
    strOutputDir = strOutputDir,
    strOutputFile = strOutputFile
  )
}
