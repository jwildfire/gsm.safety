# The data-coverage rows, as the report presents them

Reads the rows a data-coverage metric published — one per visit, the
participants with a result against the participants expected — and hands
them on in the order they were published. Like every other helper behind
the census report it counts nothing; both numbers in each row come from
the metric.

## Usage

``` r
Report_CensusCoverage(dfResults, dfMetrics, lSettings)
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

`data.frame`, one row per published coverage row, with columns `ID`,
`Figure`, `Group`, `Participants` and `Expected`. Zero rows when no
coverage figure was published.

## Absent, not empty

The thirteenth census metric did not land, and the reasons are recorded
on [gsm.safety#58](https://github.com/jwildfire/gsm.safety/issues/58):
under the standard mapping the lab domain carries no visit column, and
the expected count needs a per-visit study day no domain supplies. A
report whose settings name no coverage metric, or whose coverage metric
published nothing, gets **no coverage section at all** —
[`Report_SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_SafetyCensus.md)
drops the heading with the table. An empty coverage table would read as
a study with no data rather than as a report with no metric, which is
the exact confusion a coverage figure exists to prevent.

## The visit order is the metric's, not the label's

Rows are presented in the order the metric published them and are never
sorted by visit label. Sorting by label is what made week twelve come
before week two in the function this report replaces.

## Examples

``` r
# No coverage metric is named, so there is nothing to present.
Report_CensusCoverage(
  dfResults = data.frame(
    MetricID = character(0), Numerator = numeric(0), Denominator = numeric(0)
  ),
  dfMetrics = data.frame(
    ID = character(0), MetricID = character(0), Metric = character(0)
  ),
  lSettings = list(Coverage = list(Metrics = list()))
)
#> [1] ID           Figure       Group        Participants Expected    
#> <0 rows> (or 0-length row.names)
```
