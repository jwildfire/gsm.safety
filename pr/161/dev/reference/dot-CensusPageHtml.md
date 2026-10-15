# The census page as one HTML string

The census page as one HTML string

## Usage

``` r
.CensusPageHtml(
  dfFigures,
  dfCoverage,
  dfProvenance,
  strTitle,
  strStudyID,
  strSnapshot
)
```

## Arguments

- dfFigures:

  `data.frame` From
  [`Report_CensusFigures()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusFigures.md).

- dfCoverage:

  `data.frame` From
  [`Report_CensusCoverage()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusCoverage.md).
  Zero rows — or `NULL` — renders no coverage section at all, rather
  than an empty one.

- dfProvenance:

  `data.frame` From
  [`Report_CensusProvenance()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusProvenance.md).
  `NULL` renders no provenance section.

- strTitle:

  `character` Page title. Default: `"Safety Census"`.

- strStudyID:

  `character` Study identifier for the header.

- strSnapshot:

  `character` Snapshot date for the header.

## Value

`character(1)` — a complete, self-contained HTML document.
