# The rows one metric published, in the order it published them

The rows one metric published, in the order it published them

## Usage

``` r
CensusPublished(dfResults, strMetricID)
```

## Arguments

- dfResults:

  `data.frame` The metric results.

- strMetricID:

  `character` The reporting model's metric key, e.g.
  `"Analysis_saf0004"`.

## Value

`data.frame` of the published rows; zero rows when the metric published
none.
