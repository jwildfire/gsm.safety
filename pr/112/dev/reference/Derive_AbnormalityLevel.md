# Grade a result against the FDA abnormality level criteria

Adds the level 1, 2 or 3 abnormality grade from Appendix Tables 56
(chemistry) and 57 (hematology) of the FDA Standard Safety Tables and
Figures Integrated Guide v2.0, the criteria the guide's "analyte values
exceeding specified levels" tables count on (section 2.4.3). The levels
are cumulative, so the grade is the highest level the result meets in
the row's direction with the row's operator, `0` when the parameter is
graded and the result meets none, and `NA` when the record cannot be
graded. Requirement `FDA-RULE-002`; the sex-qualified rows are
`FDA-RULE-016`.

## Usage

``` r
Derive_AbnormalityLevel(
  dfResults,
  dfCriteria = gsm.safety::FDA_AbnormalityLevels,
  strTestCol = "TEST",
  strValueCol = "STRESN",
  strULNCol = "STNRHI",
  strUnitCol = "STRESU",
  strSexCol = NULL,
  lParameterValues = DefaultAbnormalityParameters(),
  strOutCol = "AbnormalityLevel"
)
```

## Arguments

- dfResults:

  `data.frame` Long-format results, one row per participant per test per
  visit, in the shape of `ExampleData("adbds")`.

- dfCriteria:

  `data.frame` The criteria, in the shape of
  [FDA_AbnormalityLevels](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_AbnormalityLevels.md)
  (at least `Parameter`, `Direction`, `Qualifier`, `Unit`, `Basis`,
  `Operator`, `Level1`, `Level2`, `Level3`). Default:
  `FDA_AbnormalityLevels`.

- strTestCol:

  `character` Column holding the test name. Default: `"TEST"`.

- strValueCol:

  `character` Numeric result column. Default: `"STRESN"`.

- strULNCol:

  `character` Upper-limit-of-normal column. Default: `"STNRHI"`.

- strUnitCol:

  `character` Unit column. Default: `"STRESU"`.

- strSexCol:

  `character` Sex column (`M`/`F` or `Male`/`Female`, any case), used
  for the sex-qualified rows. Default: `NULL`, which skips them.

- lParameterValues:

  Named `list` mapping each criteria `Parameter` to the test name(s) the
  data use for it. Default: the names `ExampleData("adbds")` uses.

- strOutCol:

  `character` Name of the grade column. Default: `"AbnormalityLevel"`;
  the direction and the criterion met are added as `<strOutCol>` with
  `Level` replaced by `Direction` and `Criterion`. None of the three may
  already be a column of `dfResults`: the function appends, it never
  overwrites.

## Value

`dfResults` with three columns appended: the grade (`integer` 0 to 3, or
`NA`), the direction of the row that graded it (`"low"`, `"high"`,
`"increase"`, `"decrease"`, or `NA`), and the criterion text as printed
in the guide (for example `">5.5"`), `NA` where no level was met.

## Details

What is graded, and what is left `NA`:

- `uln_multiple` rows (the liver panel, CPK, amylase, lipase, PT, PTT)
  are graded on the result divided by its own ULN, as
  [`Derive_ULNMultiple()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ULNMultiple.md)
  forms it, whatever unit the data carry.

- `absolute` rows are graded only when the record's unit matches the
  criteria's unit. The guide prints US-conventional units; a result in
  another unit is left `NA` and named in a message rather than compared
  on the wrong scale. Spellings of the same unit are folded (`mEq/L` and
  `mmol/L` for the monovalent electrolytes, `GI/L` and
  `x 10^9 cells/L`), but nothing is converted.

- Rows with a sex qualifier (HDL; hemoglobin, low) are applied only when
  `strSexCol` names a column, to records whose sex matches.

- Rows whose basis is a change or multiple of baseline (creatinine,
  eGFR, hemoglobin change) and the fasting or random glucose rows need
  columns this function does not take; they are left `NA` and reported.

- A test that `lParameterValues` does not map is left `NA` silently.

Nothing is dropped or aggregated: the input frame comes back with three
columns added, in its original row order. Where an established grading
system applies (DAIDS, CTCAE) the guide allows it in place of Tables 56
and 57 (`FDA-RULE-003`); pass it as `dfCriteria` in the same shape.

## See also

[FDA_AbnormalityLevels](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_AbnormalityLevels.md)
for the criteria and their transcription notes;
[`Derive_ULNMultiple()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ULNMultiple.md)
for the scale the ULN-multiple rows use.

Other FDA derivations:
[`Derive_ExtremeValueFlag()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ExtremeValueFlag.md),
[`Derive_ULNMultiple()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ULNMultiple.md)

## Examples

``` r
dfLabs <- ExampleData("adbds")
dfLabs <- Derive_AbnormalityLevel(dfLabs)
#> Derive_AbnormalityLevel left NA for records it could not evaluate:
#>   unit differs from the criteria's (mg/dL): Blood urea nitrogen in mmol/L, Calcium in mmol/L, Cholesterol (total) in mmol/L, Glucose in mmol/L, Phosphate in mmol/L
#>   qualifier 'Fasting' needs a column this function does not take: Glucose
#>   qualifier 'Random' needs a column this function does not take: Glucose
#>   unit differs from the criteria's (g/dL): Albumin in g/L, Protein (total) in g/L
#>   basis 'baseline_multiple' needs a baseline column this function does not take: Creatinine
#>   basis 'baseline_change' needs a baseline column this function does not take: Hemoglobin
#>   unit differs from the criteria's (cells/uL): Lymphocytes in GI/L, Platelets in GI/L
#>   needs a sex column (strSexCol) for the sex-qualified rows: Hemoglobin
dfGraded <- dfLabs[!is.na(dfLabs$AbnormalityLevel) & dfLabs$AbnormalityLevel > 0, ]
table(dfGraded$TEST, dfGraded$AbnormalityLevel)
#>                             
#>                                1   2   3
#>   Alanine Aminotransferase   102  10   0
#>   Alkaline Phosphatase       121  14  12
#>   Aspartate Aminotransferase  93   0   0
#>   Bilirubin                   15  71  30
#>   Chloride                   243  27   0
#>   Leukocytes                  35   9   0
#>   Potassium                   40   9   0
#>   Sodium                       5   2   0
```
