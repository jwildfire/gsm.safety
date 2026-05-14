# Create example data for the AE Explorer report with gsm.datasim

Create a reproducible mapped subject and adverse event example data set
from `gsm.datasim` for tests and pkgdown examples.

## Usage

``` r
MakeAeExplorerExampleData(nSubjects = 12, nSites = 3, nAe = 24, seed = 1)
```

## Arguments

- nSubjects:

  Number of synthetic subjects to generate.

- nSites:

  Number of synthetic sites to generate.

- nAe:

  Number of synthetic adverse event records to generate.

- seed:

  Random seed used to keep examples deterministic.

## Value

A named list containing `Mapped_SUBJ` and `Mapped_AE` example data.
