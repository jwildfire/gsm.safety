# FDA extreme laboratory and vital sign values suggestive of error

Appendix Tables 58, 59 and 60 of the FDA *Standard Safety Tables and
Figures: Integrated Guide*, version 2.0 (April 2025; guide section 5.2,
"Extreme Clinical Laboratory and Vital Sign Values, Version 1.0"),
transcribed row for row: the thresholds beyond which a result is treated
as a likely laboratory or recording error and removed from the guide's
mean change from baseline over time figures (Figures 6 and 9). Table 58
(section 5.2.1, pages 122 to 123) covers serum, plasma and whole blood
chemistry; Table 59 (section 5.2.2, page 123) hematology; Table 60
(section 5.2.3, page 124) vital signs.

## Usage

``` r
FDA_ExtremeValues
```

## Format

A data frame with 80 rows (40 parameters, two unit systems each) and 13
columns:

- Table:

  `integer` Guide table the row comes from: 58, 59 or 60.

- Panel:

  `character` `"General Chemistry"`, `"Hematology"` or `"Vital Signs"`.

- Parameter:

  `character` Parameter as printed, without the specimen.

- Specimen:

  `character` Specimen the guide prints in parentheses (`"serum"`,
  `"plasma"`, `"blood"`, ...), `NA` for vital signs.

- UnitSystem:

  `character` `"US"` (US conventional) or `"SI"`.

- Unit:

  `character` Unit in that system; `NA` for the unitless INR.

- Low:

  `numeric` Values below this are extreme; `NA` when the guide prints
  N/A.

- High:

  `numeric` Values above this are extreme; `NA` when the guide prints
  N/A.

- References:

  `character` The guide's reference footnote numbers for the row, within
  its table.

- GuideVersion:

  `character` `"2.0"`.

- GuideSection:

  `character` `"5.2.1"`, `"5.2.2"` or `"5.2.3"`.

- GuidePage:

  `integer` Printed page of the guide the row is on.

- Note:

  `character` Transcription note, else `NA`.

## Source

FDA CDER, *Standard Safety Tables and Figures: Integrated Guide*,
version 2.0, April 2025, Appendix 5.2,
<https://www.fda.gov/media/187065/download>.

## Details

The guide prints each parameter once with a US-conventional and an SI
column pair. This dataset is long: every parameter appears twice, once
per `UnitSystem`, so `Derive_ExtremeValueFlag()` (gsm.safety#78) can
join on the unit the data actually carries. Table 60 prints one unit
set, so its rows are repeated under both systems, except temperature,
which the guide gives in both Fahrenheit (filed as US) and Celsius
(filed as SI). A missing `Low` or `High` is an `N/A` in the guide: no
threshold in that direction.

Transcription decisions are in the `Note` column beside the row they
concern. Non-ASCII characters in the guide are written in ASCII (`u` for
the micro sign). The build script and the hand-checked CSV are in the
repository's `data-raw/` directory.

## See also

[FDA_AbnormalityLevels](https://jwildfire.github.io/gsm.safety/dev/reference/FDA_AbnormalityLevels.md)
for the abnormality level criteria, `Derive_ExtremeValueFlag()`
(gsm.safety#78) for the exclusion rule applied to lab data.

## Examples

``` r
data(FDA_ExtremeValues)
subset(FDA_ExtremeValues, Parameter == "Glucose")
#>    Table             Panel Parameter Specimen UnitSystem   Unit  Low High
#> 11    58 General Chemistry   Glucose   plasma         US  mg/dL 10.0 2700
#> 12    58 General Chemistry   Glucose   plasma         SI mmol/L  0.6  150
#>    References GuideVersion GuideSection GuidePage Note
#> 11       2, 7          2.0        5.2.1       122 <NA>
#> 12       2, 7          2.0        5.2.1       122 <NA>
```
