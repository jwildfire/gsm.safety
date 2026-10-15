# Participant-level QTc prolongation tier from ECG data

Scores every participant with a post-baseline QTc against the ICH E14
outlier cut-points the `qt_explorer` chart already draws, taken from
`inst/schema/qt-explorer.json` (`absolute_thresholds: [450, 480, 500]`,
`change_thresholds: [30, 60]`). Both criteria matter: on the demo study
the absolute cut alone flags one participant while the change cut flags
ten, so a metric built on absolute values alone would have looked
healthy and said nothing.

## Usage

``` r
Input_QtProlongation(
  dfECG,
  strIDCol = "subjid",
  strMeasureCol = "egtstnam",
  strValueCol = "egstresn",
  strBaselineCol = "egbase",
  strChangeCol = "egchg",
  strBaselineFlagCol = "egblfl",
  strMeasure = "QTcF",
  vAbsoluteThresholds = c(450, 480, 500),
  vChangeThresholds = c(30, 60),
  strGroupLevel = "Subject"
)
```

## Arguments

- dfECG:

  `data.frame` Long-format ECG records, one row per participant per
  parameter per visit.

- strIDCol:

  `character` Participant ID column. Default: `"subjid"`.

- strMeasureCol:

  `character` Column holding the ECG parameter name. Default:
  `"egtstnam"`.

- strValueCol:

  `character` Numeric result column. Default: `"egstresn"`.

- strBaselineCol:

  `character` Column holding the participant's baseline value. Default:
  `"egbase"`.

- strChangeCol:

  `character` Column holding change from baseline; when absent or
  non-numeric for a row, change is derived as value − baseline. Default:
  `"egchg"`.

- strBaselineFlagCol:

  `character` Baseline-record flag column, used to drop baseline records
  from scoring. Default: `"egblfl"`.

- strMeasure:

  `character` The corrected-QT parameter to score. Default: `"QTcF"`.

- vAbsoluteThresholds:

  `numeric` Ascending absolute cut-points in ms. Default:
  `c(450, 480, 500)`.

- vChangeThresholds:

  `numeric` Ascending change-from-baseline cut-points in ms. Default:
  `c(30, 60)`.

- strGroupLevel:

  `character` Group level to record. Default: `"Subject"`.

## Value

`data.frame` conforming to `analyticsInput`, one row per participant
with at least one post-baseline value, carrying the max absolute value,
the max change and the baseline as evidence columns.

## Details

The tier ladder:

|  |  |
|----|----|
| Tier | Rule |
| 0 | no post-baseline value at the lowest absolute cut and no change at the lowest change cut |
| 1 | max QTc at the first absolute cut (450 ms) *or* max change at the first change cut (30 ms) |
| 2 | max QTc at the second absolute cut (480 ms) |
| 3 | max QTc at the third absolute cut (500 ms) *or* max change at the second change cut (60 ms) |

Tier 3 is the conventional ICH E14 outlier pair (\>500 ms or \>60 ms
change). Only post-baseline records are scored — a baseline value is the
reference, not a finding — and a participant with a baseline but no
post-baseline ECG gets no row, because an unmeasured interval is not a
normal one.

## Examples

``` r
dfECG <- data.frame(
  subjid = c("S1", "S1", "S2", "S2"),
  egtstnam = "QTcF",
  egstresn = c(400, 505, 390, 415),
  egbase = c(400, 400, 390, 390),
  egchg = c(0, 105, 0, 25),
  egblfl = c("Y", "", "Y", "")
)
Input_QtProlongation(dfECG)
#>   SubjectID GroupID GroupLevel Numerator Denominator Metric Measure MaxValue
#> 1        S1      S1    Subject         3           1      3    QTcF      505
#> 2        S2      S2    Subject         0           1      0    QTcF      415
#>   MaxChange Baseline
#> 1       105      400
#> 2        25      390
```
