% Generated manually for early scaffold; roxygen2 can refresh later.
\name{Report_AE_Explorer}
\alias{Report_AE_Explorer}
\title{Render an interactive AE Explorer report}
\usage{
Report_AE_Explorer(
  lData,
  lSettings,
  strOutputDir = getwd(),
  strOutputFile = "ae_explorer"
)
}
\arguments{
\item{lData}{A named list containing \code{Mapped_SUBJ} and \code{Mapped_AE} data frames.}
\item{lSettings}{AE Explorer settings from \code{MakeAeExplorerSettings()}.}
\item{strOutputDir}{Directory where the HTML report should be written.}
\item{strOutputFile}{Output file stem or filename. \code{.html} is appended when absent.}
}
\value{A list with the report path, htmlwidget, and summary tables.}
\description{
Render an interactive AE Explorer report by validating mapped AE inputs,
initializing settings with \code{safetyCharts::init_aeExplorer()}, rendering
the widget with \code{safetyCharts::render_widget()}, and writing a standalone
HTML artifact for workflow and pkgdown examples.
}
