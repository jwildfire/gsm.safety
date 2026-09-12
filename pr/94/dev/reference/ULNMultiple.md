# The result as a multiple of its own upper limit of normal

The one rule behind
[`Derive_ULNMultiple()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ULNMultiple.md)
and the ULN-multiple rows of
[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md):
value over ULN, `NA` where either is missing or the ULN is not positive.

## Usage

``` r
ULNMultiple(nValue, nULN)
```

## Arguments

- nValue:

  `numeric` Results.

- nULN:

  `numeric` Upper limits of normal, same length.

## Value

`numeric` of `length(nValue)`.
