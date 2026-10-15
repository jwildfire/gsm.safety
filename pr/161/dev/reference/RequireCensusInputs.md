# Guard the inputs every census report helper shares

Guard the inputs every census report helper shares

## Usage

``` r
RequireCensusInputs(dfResults, dfMetrics, lSettings)
```

## Arguments

- dfResults:

  `data.frame` The metric results.

- dfMetrics:

  `data.frame` The metric definitions.

- lSettings:

  `list` The report's settings.

## Value

`NULL`, invisibly. Stops when an input cannot be read.
