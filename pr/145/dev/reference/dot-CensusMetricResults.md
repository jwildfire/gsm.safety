# Run every census metric the supplied domains can support

A metric whose declared domains are not all here is not run, and a
metric that stops on what it was given is reported rather than
swallowed. Both leave the figure absent, which is what the caller sees;
neither leaves a zero, and neither happens quietly.

## Usage

``` r
.CensusMetricResults(lWorkflows, lDomains)
```

## Arguments

- lWorkflows:

  Named `list` of metric definitions.

- lDomains:

  Named `list` of the mapped domains.

## Value

`data.frame` of the published rows, with a `MetricID` column, in the
shape
[`Report_CensusFigures()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusFigures.md)
reads.
