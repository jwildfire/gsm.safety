# FDA abnormality level criteria for laboratory results

Appendix Tables 56 and 57 of the FDA *Standard Safety Tables and
Figures: Integrated Guide*, version 2.0 (April 2025; CDER BIRRS, MAPP
6025.9), transcribed row for row: the level 1, 2 and 3 abnormality
thresholds the guide uses to count "subjects with analyte values
exceeding specified levels" (Tables 20 and 52 to 55) when no established
grading system such as DAIDS or CTCAE applies. Table 56 (guide section
5.1.1, pages 119 to 120) covers general chemistry, kidney function,
liver biochemistry and lipids; Table 57 (section 5.1.2, page 121) covers
the complete blood count, the WBC differential and coagulation studies.
The guide provides the criteria "for the purpose of identifying
outliers"; the individual thresholds do not correspond to specific
safety outcomes.

## Usage

``` r
FDA_AbnormalityLevels
```

## Format

A data frame with 46 rows and 18 columns:

- Table:

  `integer` Guide table the row comes from: 56 or 57.

- Panel:

  `character` Panel heading in the table, e.g. `"Liver Biochemistry"`.

- Parameter:

  `character` Laboratory parameter as printed, without the direction.

- Direction:

  `character` `"low"`, `"high"`, `"increase"` or `"decrease"`.

- Qualifier:

  `character` Sex or fasting-state qualifier the guide attaches to the
  row, else `NA`.

- Unit:

  `character` Unit printed with the parameter.

- Basis:

  `character` What the thresholds compare against; see the table above.

- Operator:

  `character` Comparison operator shared by the row's levels: `"<"`,
  `">"` or `">="`.

- Level1, Level2, Level3:

  `numeric` Threshold at each level; `NA` where the guide prints N/A.

- Level1Text, Level2Text, Level3Text:

  `character` The criterion as printed.

- GuideVersion:

  `character` `"2.0"`.

- GuideSection:

  `character` `"5.1.1"` for Table 56, `"5.1.2"` for Table 57.

- GuidePage:

  `integer` Printed page of the guide the row is on.

- Note:

  `character` Transcription note, else `NA`.

## Source

FDA CDER, *Standard Safety Tables and Figures: Integrated Guide*,
version 2.0, April 2025, Appendix 5.1,
<https://www.fda.gov/media/187065/download>.

## Details

One row per printed row: a parameter in one direction, with a qualifier
where the guide splits a row by sex or by fasting state. The three
levels are cumulative — a level 3 result also meets levels 1 and 2 — and
every row compares with one operator. `Basis` says what the threshold is
compared against:

|  |  |  |
|----|----|----|
| `Basis` | The level is | Example |
| `absolute` | a value in `Unit` | Sodium, low: `<132` mEq/L |
| `uln_multiple` | a multiple of the upper limit of normal | ALT, high: `>3.0 x ULN` |
| `baseline_multiple` | a multiple of the participant's baseline | Creatinine, increase: `>=1.5 x baseline` |
| `baseline_percent_decrease` | a percentage decrease from baseline | eGFR, decrease: `>=25% decrease` |
| `baseline_change` | an absolute change from baseline in `Unit` | Hemoglobin, decrease: `>1.5 dec. from baseline` |

[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md)
(gsm.safety#78) applies the `absolute` and `uln_multiple` rows; the
baseline-relative bases need a baseline column and are left to the phase
1 engines.

Transcription decisions are recorded in the `Note` column beside the row
they concern: the hemoglobin level 1 ranges are read as the upper bound
because the levels are cumulative, and the platelet unit is kept as
printed. Non-ASCII characters in the guide are written in ASCII (`u` for
the micro sign, `>=` for the greater-than-or-equal sign). The build
script and the hand-checked CSV are in the repository's `data-raw/`
directory.

## See also

[FDA_ExtremeValues](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_ExtremeValues.md)
for the companion extreme-value thresholds,
[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md)
(gsm.safety#78) for the grading rule applied to lab data.

## Examples

``` r
data(FDA_AbnormalityLevels)
subset(
  FDA_AbnormalityLevels,
  Panel == "Liver Biochemistry",
  select = c(Parameter, Direction, Basis, Level1, Level2, Level3)
)
#>                     Parameter Direction        Basis Level1 Level2 Level3
#> 25       Alkaline phosphatase      high uln_multiple    1.5      2      3
#> 26   Alanine Aminotransferase      high uln_multiple    3.0      5     10
#> 27 Aspartate Aminotransferase      high uln_multiple    3.0      5     10
#> 28            Total Bilirubin      high uln_multiple    1.5      2      3
```
