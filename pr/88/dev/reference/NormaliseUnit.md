# Normalise a unit string for matching

Case, spacing and the micro sign are presentation; a handful of
spellings the guide and the example data use for the same unit are
folded together. Nothing here converts between units: `mg/dL` never
matches `mmol/L`.

## Usage

``` r
NormaliseUnit(chrUnit)
```

## Arguments

- chrUnit:

  `character` Unit strings.

## Value

`character` Normalised keys, `NA` where the input is missing.
