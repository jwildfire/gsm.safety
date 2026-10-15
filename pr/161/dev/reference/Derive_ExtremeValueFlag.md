# Flag results beyond the FDA extreme-value thresholds

Adds the flag the FDA Standard Safety Tables and Figures Integrated
Guide v2.0 removes records on: a result below the low or above the high
threshold of Appendix Tables 58 (chemistry), 59 (hematology) or 60
(vital signs) is treated as a likely laboratory or recording error and
excluded from the mean change from baseline over time figures (sections
2.4, 2.4.2, 2.5.1). Requirement `FDA-RULE-004`; the unit matching is
`FDA-RULE-005`.

## Usage

``` r
Derive_ExtremeValueFlag(
  dfResults,
  dfThresholds = gsm.safety::FDA_ExtremeValues,
  strTestCol = "TEST",
  strValueCol = "STRESN",
  strUnitCol = "STRESU",
  lParameterValues = DefaultExtremeParameters(),
  strOutCol = "ExtremeValueFlag"
)
```

## Arguments

- dfResults:

  `data.frame` Long-format results, one row per participant per test per
  visit, in the shape of `ExampleData("adbds")`.

- dfThresholds:

  `data.frame` The thresholds, in the shape of
  [FDA_ExtremeValues](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_ExtremeValues.md)
  (at least `Parameter`, `UnitSystem`, `Unit`, `Low`, `High`). Default:
  `FDA_ExtremeValues`.

- strTestCol:

  `character` Column holding the test name. Default: `"TEST"`.

- strValueCol:

  `character` Numeric result column. Default: `"STRESN"`.

- strUnitCol:

  `character` Unit column. Default: `"STRESU"`.

- lParameterValues:

  Named `list` mapping each threshold `Parameter` to the test name(s)
  the data use for it. Default: the names `ExampleData("adbds")` uses.

- strOutCol:

  `character` Name of the flag column. Default: `"ExtremeValueFlag"`;
  the direction is added as `<strOutCol>` with `Flag` replaced by
  `Direction`. Neither may already be a column of `dfResults`: the
  function appends, it never overwrites.

## Value

`dfResults` with two columns appended: the flag (`logical`, `TRUE`
beyond a threshold, `FALSE` within, `NA` where the parameter or unit
could not be matched or the result is missing) and the direction
(`"low"`, `"high"` or `NA`).

## Details

The guide prints every threshold in US-conventional and SI units, and
[FDA_ExtremeValues](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_ExtremeValues.md)
carries both. A record is compared against the row for the unit it
carries: a result in `mg/dL` against the US thresholds, in `mmol/L`
against the SI ones. A record whose unit matches neither is left `NA`
and named in a message rather than compared on the wrong scale;
spellings of the same unit are folded (and mEq/L and mmol/L treated as
one unit for the monovalent electrolytes only) but nothing is converted.
A missing threshold in one direction (an `N/A` in the guide) is no bound
in that direction, and the threshold itself is not extreme.

The flag is added, never applied: nothing is dropped or aggregated, and
the renderer that draws a mean-change figure filters on it (the design's
L1 contract).

## See also

[FDA_ExtremeValues](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_ExtremeValues.md)
for the thresholds and their provenance.

Other FDA derivations:
[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md),
[`Derive_ULNMultiple()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ULNMultiple.md)

## Examples

``` r
dfLabs <- ExampleData("adbds")
dfLabs <- Derive_ExtremeValueFlag(dfLabs)
#> Derive_ExtremeValueFlag left NA for records it could not evaluate:
#>   unit matches neither the US-conventional nor the SI threshold row: Hematocrit in 1, Hemoglobin in mmol/L, Lymphocytes in GI/L, Platelets in GI/L
table(matched = !is.na(dfLabs$ExtremeValueFlag), extreme = dfLabs$ExtremeValueFlag, useNA = "ifany")
#>        extreme
#> matched FALSE  <NA>
#>   FALSE     0 13231
#>   TRUE  44698     0
```
