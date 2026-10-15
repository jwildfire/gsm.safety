# The `Disposition` table: the states a metric publishes

Three states, because three metrics. `Ongoing` and the
`Discontinued - <reason>` breakdown were read out of a free-text reason
column, and `Not in the disposition domain` was a subtraction; none of
them is a published figure, so none of them is here.

## Usage

``` r
.CENSUS_LEGACY_STATES
```

## Format

An object of class `data.frame` with 3 rows and 2 columns.
