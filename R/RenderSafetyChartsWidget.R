#' Save an initialized safetyCharts widget as standalone HTML
#'
#' @param lInitialized A list returned by a `safetyCharts::init_*()` helper with
#'   `data` and `settings` entries.
#' @param strWidgetName Name of the safetyCharts htmlwidget to render.
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when absent.
#'
#' @return A list with the report path and htmlwidget.
#' @export
RenderSafetyChartsWidget <- function(lInitialized,
                                     strWidgetName,
                                     strOutputDir = getwd(),
                                     strOutputFile = strWidgetName) {
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(strOutputDir, strOutputFile)

  widget <- safetyCharts::render_widget(
    strWidgetName,
    lInitialized$data,
    lInitialized$settings
  )
  widget <- htmlwidgets::prependContent(
    widget,
    htmltools::tags$script(
      htmltools::HTML("var Shiny = window.Shiny || null; window.Shiny = Shiny;")
    )
  )
  htmlwidgets::saveWidget(widget, file = strOutputPath, selfcontained = TRUE)

  list(
    path = normalizePath(strOutputPath, winslash = "/", mustWork = FALSE),
    widget = widget,
    initialized = lInitialized
  )
}
