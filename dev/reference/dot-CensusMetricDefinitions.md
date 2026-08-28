# The metric definitions, in the shape the reporting model carries them

[`gsm.reporting::MakeMetric()`](https://gilead-public.github.io/gsm.reporting/reference/MakeMetric.html)
builds this from the same yaml in a full pipeline. It is rebuilt here
rather than depended on: gsm.reporting is a suggested package, and this
function has to work for a caller who has one study's domains and no
reporting model.

## Usage

``` r
.CensusMetricDefinitions(lWorkflows)
```

## Arguments

- lWorkflows:

  Named `list` of metric definitions.

## Value

`data.frame` with `ID`, `MetricID`, `Metric`, `Numerator` and
`Denominator`.
