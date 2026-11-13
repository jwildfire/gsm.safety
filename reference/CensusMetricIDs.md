# Metric IDs from a settings entry

The workflow's settings are read from YAML, where a list of one and a
list of many arrive in different shapes and an omitted key arrives as
`NULL`.

## Usage

``` r
CensusMetricIDs(x)
```

## Arguments

- x:

  Settings value naming metric IDs.

## Value

`character`, empty when nothing is named.
