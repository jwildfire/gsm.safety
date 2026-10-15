# Express a result as a multiple of its upper limit of normal

Adds one numeric column: the result divided by the record's own upper
limit of normal. This is the scale the FDA Standard Safety Tables and
Figures Integrated Guide (v2.0) draws the DILI screening plots on
(Figures 7 and 8, section 2.4.4) and the scale every `x ULN` threshold
in its Appendix Tables 56 and 57 is read on. The guide normalises to the
*reported* ULN because normal ranges vary between laboratory sites, so
the denominator is the record's own, never a study-wide constant.
Requirement `FDA-RULE-001` in `requirements/fda-stf.md`.

## Usage

``` r
Derive_ULNMultiple(
  dfResults,
  strValueCol = "STRESN",
  strULNCol = "STNRHI",
  strOutCol = "ULNMultiple"
)
```

## Arguments

- dfResults:

  `data.frame` Long-format results, one row per participant per test per
  visit, in the shape of `ExampleData("adbds")`.

- strValueCol:

  `character` Numeric result column. Default: `"STRESN"`.

- strULNCol:

  `character` Upper-limit-of-normal column. Default: `"STNRHI"`.

- strOutCol:

  `character` Name of the column to add. Default: `"ULNMultiple"`. Must
  not already be a column of `dfResults`: the function appends, it never
  overwrites.

## Value

`dfResults` with `strOutCol` appended: `numeric`, the result as a
multiple of ULN, `NA` where it cannot be formed.

## Details

The multiple is `NA` where the result is missing or the ULN is missing,
non-numeric or not positive. Nothing is dropped and nothing is
aggregated: the input frame comes back with the column added, in its
original row order (the design's L1 contract).
[`Input_HysLaw()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_HysLaw.md)
computes the same quantity internally for its peak-per-participant
reduction; the two agree record for record.

## See also

[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md),
which grades the multiple against Tables 56 and 57;
[`Input_HysLaw()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_HysLaw.md),
which reduces it to a peak per participant.

Other FDA derivations:
[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md),
[`Derive_ExtremeValueFlag()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ExtremeValueFlag.md)

## Examples

``` r
dfLabs <- ExampleData("adbds")
dfLabs <- Derive_ULNMultiple(dfLabs)
dfALT <- dfLabs[dfLabs$TEST == "Alanine Aminotransferase", ]
head(dfALT[, c("USUBJID", "VISIT", "STRESN", "STNRHI", "ULNMultiple")])
#>        USUBJID    VISIT STRESN STNRHI ULNMultiple
#> 21 01-701-1015 Baseline     27     34   0.7941176
#> 22 01-701-1015   Week 2     41     34   1.2058824
#> 23 01-701-1015   Week 4     18     34   0.5294118
#> 24 01-701-1015   Week 6     26     34   0.7647059
#> 25 01-701-1015   Week 8     22     34   0.6470588
#> 26 01-701-1015  Week 12     27     34   0.7941176
```
