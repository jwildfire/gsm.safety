% Generated manually for early scaffold; roxygen2 can refresh later.
\name{MakeAeExplorerExampleData}
\alias{MakeAeExplorerExampleData}
\title{Create example data for the AE Explorer report with gsm.datasim}
\usage{
MakeAeExplorerExampleData(nSubjects = 12, nSites = 3, nAe = 24, seed = 1)
}
\arguments{
\item{nSubjects}{Number of synthetic subjects to generate.}
\item{nSites}{Number of synthetic sites to generate.}
\item{nAe}{Number of synthetic adverse event records to generate.}
\item{seed}{Random seed used to keep examples deterministic.}
}
\value{A named list containing \code{Mapped_SUBJ} and \code{Mapped_AE} example data.}
\description{
Create a reproducible mapped subject and adverse event example data set from
\code{gsm.datasim} for tests and pkgdown examples.
}
