# Participant-level Hy's Law candidate tier from liver chemistry

Scores every participant with liver chemistry against the eDISH
quadrants the `hep_explorer` chart already draws, using that chart's own
cut-points from `inst/schema/hep-explorer.json`
(`cuts.defaults.relative_uln` = 3 for the aminotransferases,
`cuts.TB.relative_uln` = 2 for total bilirubin). Each participant is
reduced to their **peak** ×ULN value per measure — the same
one-point-per-participant reduction the chart performs — so a flag and
the point a reviewer sees on the chart are the same observation.

## Usage

``` r
Input_HysLaw(
  dfLabs,
  strIDCol = "subjid",
  strMeasureCol = "lbtstnam",
  strValueCol = "lbstresn",
  strULNCol = "lbstnrhi",
  lMeasureValues = list(ALT = "Alanine Aminotransferase", AST =
    "Aspartate Aminotransferase", TB = "Bilirubin", ALP = "Alkaline Phosphatase"),
  nAminotransferaseCut = 3,
  nBilirubinCut = 2,
  nCholestaticCut = 2,
  strGroupLevel = "Subject"
)
```

## Arguments

- dfLabs:

  `data.frame` Long-format lab results, one row per participant per
  measure per visit.

- strIDCol:

  `character` Participant ID column. Default: `"subjid"`.

- strMeasureCol:

  `character` Column holding the measure name. Default: `"lbtstnam"`.

- strValueCol:

  `character` Numeric result column. Default: `"lbstresn"`.

- strULNCol:

  `character` Upper-limit-of-normal column, the denominator of the ×ULN
  standardisation. Default: `"lbstnrhi"`.

- lMeasureValues:

  `list` Map of the measure keys `ALT`, `AST`, `TB` and `ALP` to the
  measure strings in the data — the same mapping the chart's
  `measure_values` setting takes.

- nAminotransferaseCut:

  `numeric` ×ULN cut for ALT / AST. Default: `3`.

- nBilirubinCut:

  `numeric` ×ULN cut for total bilirubin. Default: `2`.

- nCholestaticCut:

  `numeric` ×ULN cut at or above which the pattern is read as
  cholestatic, holding the participant at tier 2. Default: `2`.

- strGroupLevel:

  `character` Group level to record. Default: `"Subject"`.

## Value

`data.frame` conforming to `analyticsInput`, one row per participant
with at least one usable liver result, carrying the peak ×ULN of each
measure and the R ratio as evidence columns.

## Details

The tier ladder, ordered by how much review the participant warrants:

|  |  |  |
|----|----|----|
| Tier | eDISH region | Rule |
| 0 | normal | neither axis at its cut |
| 1 | Temple's Corollary *or* hyperbilirubinaemia | exactly one axis at its cut |
| 2 | both axes, cholestatic pattern | both axes at their cut, peak ALP at or above the cholestatic cut |
| 3 | **potential Hy's Law** | both axes at their cut, peak ALP below the cholestatic cut |

Tier 3 is a *candidate*, not an adjudicated Hy's Law case. Two standard
criteria are deliberately out of scope here and belong to case review:
the requirement that the aminotransferase and bilirubin elevations be
temporally associated (peaks are taken independently, exactly as eDISH
does), and the exclusion of other causes of liver injury.

## Examples

``` r
dfLabs <- data.frame(
  subjid = rep(c("S1", "S2"), each = 4),
  lbtstnam = rep(c("ALT", "AST", "TB", "ALP"), 2),
  lbstresn = c(150, 120, 60, 90, 20, 25, 8, 80),
  lbstnrhi = c(40, 40, 20, 120, 40, 40, 20, 120)
)
Input_HysLaw(
  dfLabs,
  lMeasureValues = list(ALT = "ALT", AST = "AST", TB = "TB", ALP = "ALP")
)
#>   SubjectID GroupID GroupLevel Numerator Denominator Metric PeakALT_xULN
#> 1        S1      S1    Subject         3           1      3         3.75
#> 2        S2      S2    Subject         0           1      0         0.50
#>   PeakAST_xULN PeakTB_xULN PeakALP_xULN RRatio           Quadrant
#> 1        3.000         3.0        0.750  5.000 Potential Hy's Law
#> 2        0.625         0.4        0.667  0.938             Normal
```
