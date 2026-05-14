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
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(strOutputDir, strOutputFile)

  widget <- safetyCharts::render_widget(
    "aeExplorer",
    lInitialized$data,
    lInitialized$settings
  )
  htmlwidgets::saveWidget(widget, file = strOutputPath, selfcontained = TRUE)

  list(
    path = normalizePath(strOutputPath, winslash = "/", mustWork = FALSE),
    widget = widget,
    initialized = lInitialized
  )
}
