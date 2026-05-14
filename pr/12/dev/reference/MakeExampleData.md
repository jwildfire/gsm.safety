# Create example data for safety renderers with gsm.datasim

Create reproducible mapped example data domains from `gsm.datasim` for
safety renderer tests and pkgdown examples.

## Usage

``` r
MakeExampleData(nSubjects = 12, nSites = 3, nAe = 24, seed = 1)
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

A named list containing mapped example data domains.
