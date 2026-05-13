% Generated manually for early scaffold; roxygen2 can refresh later.
\name{Report_AE_Explorer}
\alias{Report_AE_Explorer}
\title{Render a static AE Explorer report}
\usage{
Report_AE_Explorer(
  lData,
  lSettings,
  lManifest,
  strOutputDir = getwd(),
  strOutputFile = "ae_explorer"
)
}
\arguments{
\item{lData}{A named list containing \code{Mapped_SUBJ} and \code{Mapped_AE} data frames.}
\item{lSettings}{AE Explorer settings from \code{MakeAeExplorerSettings()}.}
\item{lManifest}{AE Explorer manifest from \code{MakeAeExplorerManifest()}.}
\item{strOutputDir}{Directory where the HTML report should be written.}
\item{strOutputFile}{Output file stem or filename. \code{.html} is appended when absent.}
}
\value{A list with the report path, HTML, manifest, and summary tables.}
\description{
Render a lightweight static AE Explorer report that validates mapped AE inputs,
summarizes adverse events by preferred term and body system, and writes an HTML
artifact for workflow and pkgdown examples.
}
