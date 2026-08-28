# Render the census report

Writes the safety census as one self-contained HTML page from the tables
the report workflow's other steps assembled. It is the last step of
`inst/workflow/4_modules/safety_census.yaml`, and like every step before
it, it reads: it lays out figures it did not compute.

## Usage

``` r
Report_SafetyCensus(
  dfFigures,
  dfCoverage = NULL,
  dfProvenance = NULL,
  dfResults = NULL,
  strTitle = "Safety Census",
  strOutputDir = getwd(),
  strOutputFile = NULL
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

- dfResults:

  `data.frame` The metric results, read only for the study identifier
  and snapshot date in the page header.

- strTitle:

  `character` Page title. Default: `"Safety Census"`.

- strOutputDir:

  `character` Directory to write into. Default:
  [`getwd()`](https://rdrr.io/r/base/getwd.html).

- strOutputFile:

  `character` File name. Default: a name built from the study and
  snapshot date.

## Value

The path of the written page, invisibly.

## What the page holds

Each section of figures the workflow declares, every figure beside the
denominator its own metric published; then the coverage table, **only if
a coverage figure was published**; then what every metric published,
verbatim, including the metrics that published nothing.

Nothing on the page flags. There is no flag column, no colour carrying a
verdict and no cut-point — D0023.3, and the same rule the metrics follow
by declaring no threshold and publishing an empty flag.

## Examples

``` r
dfFigures <- data.frame(
  Section = "Population", ID = "saf0004", Figure = "Deaths (Study)",
  Value = 13, Unit = NA_character_, Denominator = 762,
  DenominatorLabel = "Enrolled Participant"
)
strPath <- Report_SafetyCensus(dfFigures, strOutputDir = tempdir())
```
