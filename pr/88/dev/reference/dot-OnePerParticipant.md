# One row per participant

One row per participant

## Usage

``` r
.OnePerParticipant(df, strIDCol)
```

## Arguments

- df:

  `data.frame` to reduce.

- strIDCol:

  `character` Participant ID column.

## Value

`df` with later rows for an already-seen participant dropped.
