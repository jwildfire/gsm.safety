# The census figures, as the report presents them

Reads the rows the census metrics published and lays them out in the
order and the sections the report workflow declares. It counts nothing:
every value on the page is the `Numerator` a metric published, beside
the `Denominator` that same metric published, under the labels that
metric's own definition carries. A figure the metrics did not publish is
not here — see
[`Report_CensusProvenance()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusProvenance.md),
which names it as absent rather than leaving a blank row on the page.

## Usage

``` r
Report_CensusFigures(dfResults, dfMetrics, lSettings)
```

## Arguments

- dfResults:

  `data.frame` The reporting model's results — `Reporting_Results`, one
  row per metric per group, carrying `MetricID`, `Numerator` and
  `Denominator`.

- dfMetrics:

  `data.frame` The reporting model's metric definitions —
  `Reporting_Metrics`, carrying `ID`, `MetricID`, `Metric` and the
  `Numerator` and `Denominator` labels.

- lSettings:

  `list` The report workflow's settings: `Sections`, each a `Title` and
  the `Metrics` read out under it, and `PersonTime`, naming the metric
  IDs published in days along with `DaysPerYear` and the `Unit` to
  present them in.

## Value

`data.frame`, one row per published figure, with columns `Section`,
`ID`, `Figure`, `Value`, `Unit`, `Denominator` and `DenominatorLabel`.

## Days published, years presented

The person-time metrics publish participant-days, because days are the
number actually summed and a metric publishing years would publish a
figure nothing in the pipeline can check against the domain it came
from. The report divides, and only for the metric IDs the workflow names
under `PersonTime`. The published days stay on the page in the
provenance table, so the division is checkable rather than taken on
trust.

## Nothing flags

D0023.3 — the census metrics declare no threshold and publish an empty
flag, and there is no flag column here. A result that arrives carrying a
flag is refused rather than presented; see
[`RefuseFlaggedResults()`](https://jwildfire.github.io/gsm.safety/dev/reference/RefuseFlaggedResults.md).

## Examples

``` r
dfResults <- data.frame(
  MetricID = "Analysis_saf0004", GroupID = "AA-AA-000-0000",
  GroupLevel = "Study", Numerator = 13, Denominator = 762,
  Metric = 13 / 762, Score = 13, Flag = NA_integer_
)
dfMetrics <- data.frame(
  ID = "saf0004", MetricID = "Analysis_saf0004",
  Metric = "Deaths (Study)", Numerator = "Participants Who Died",
  Denominator = "Enrolled Participant"
)
Report_CensusFigures(
  dfResults, dfMetrics,
  lSettings = list(
    Sections = list(list(Title = "Population", Metrics = list("saf0004")))
  )
)
#>      Section      ID         Figure Value Unit Denominator     DenominatorLabel
#> 1 Population saf0004 Deaths (Study)    13 <NA>         762 Enrolled Participant
```
