% Generated manually for early scaffold; roxygen2 can refresh later.
\name{MakeExampleData}
\alias{MakeExampleData}
\title{Create example data for safety renderers with gsm.datasim}
\usage{
MakeExampleData(nSubjects = 12, nSites = 3, nAe = 24, seed = 1)
}
\arguments{
\item{nSubjects}{Number of synthetic subjects to generate.}
\item{nSites}{Number of synthetic sites to generate.}
\item{nAe}{Number of synthetic adverse event records to generate.}
\item{seed}{Random seed used to keep examples deterministic.}
}
\value{A named list containing mapped example data domains.}
\description{
Create reproducible mapped example data domains from \code{gsm.datasim} for
safety renderer tests and pkgdown examples.
}
