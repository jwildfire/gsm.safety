# Worst (maximum) value of `strValueCol` per participant, NA-safe

Returns a named numeric vector keyed by participant ID. Participants
whose every value is missing or non-finite are dropped rather than
returned as `-Inf`, so "no usable result" never reads as a low result.

## Usage

``` r
PeakByParticipant(df, strIDCol, strValueCol)
```

## Arguments

- df:

  `data.frame` Long-format records.

- strIDCol:

  `character` Participant ID column.

- strValueCol:

  `character` Numeric column to reduce.

## Value

Named `numeric`, one element per participant with at least one finite
value.
