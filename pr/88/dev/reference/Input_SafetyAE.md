# Participant-level serious / related / discontinuation AE tier

Scores every participant against the seriousness, causality and
action-taken fields the `ae_explorer` and `ae_timelines` charts already
filter on.

## Usage

``` r
Input_SafetyAE(
  dfAE,
  strIDCol = "subjid",
  strSeriousCol = "aeser",
  strRelatedCol = "aerel",
  strGradeCol = "aetoxgr",
  strActionCol = NULL,
  chrYesValues = c("Y", "YES", "TRUE", "1"),
  chrDiscontinuationValues = c("DRUG WITHDRAWN", "DISCONTINUED",
    "PERMANENTLY DISCONTINUED"),
  nSeriousRelatedGrade = 4,
  dfSubjects = NULL,
  strSubjectIDCol = "subjid",
  strGroupLevel = "Subject"
)
```

## Arguments

- dfAE:

  `data.frame` Long-format adverse events, one row per event.

- strIDCol:

  `character` Participant ID column. Default: `"subjid"`.

- strSeriousCol:

  `character` Seriousness flag column. Default: `"aeser"`.

- strRelatedCol:

  `character` Causality / relatedness flag column. Default: `"aerel"`.

- strGradeCol:

  `character` Numeric severity grade column (CTCAE). Default:
  `"aetoxgr"`.

- strActionCol:

  `character` or `NULL` Action-taken column; the discontinuation leg
  reads this. Default: `NULL` — inactive.

- chrYesValues:

  `character` Values of the flag columns read as "yes". Default:
  `c("Y", "YES", "TRUE", "1")`.

- chrDiscontinuationValues:

  `character` Values of `strActionCol` read as study-drug
  discontinuation. Default:
  `c("DRUG WITHDRAWN", "DISCONTINUED", "PERMANENTLY DISCONTINUED")`.

- nSeriousRelatedGrade:

  `numeric` Severity grade at or above which a serious, related AE
  reaches tier 3. Default: `4`.

- dfSubjects:

  `data.frame` or `NULL` Subject-level domain. When supplied, every
  enrolled participant is scored, so a participant with no AE at all is
  an explicit tier 0 rather than an absent row — for this metric absence
  of events is a real finding, not missing data. Default: `NULL`.

- strSubjectIDCol:

  `character` Participant ID column in `dfSubjects`. Default:
  `"subjid"`.

- strGroupLevel:

  `character` Group level to record. Default: `"Subject"`.

## Value

`data.frame` conforming to `analyticsInput`, one row per participant,
carrying the counts behind the tier as evidence columns.

## Details

Unlike the liver and QT metrics, this one has no published cut-point to
inherit — seriousness and relatedness are flags, not scales — so the
tier ladder is the design decision, and it is the difference between a
review queue and a list of most of the study. Measured on the demo
study, "any serious AE" reaches 41.7% of participants and "any related
AE" 67.8%: neither triages anything. Severity is what separates them:

|  |  |
|----|----|
| Tier | Rule |
| 0 | no serious, related or discontinuation AE |
| 1 | a related AE, not serious |
| 2 | a serious AE, or an AE whose action taken was study-drug discontinuation |
| 3 | a serious **and** related AE at or above the severity grade cut |

Tier 3 defaults to CTCAE grade 4 (life-threatening), the shape of an
expedited safety report: serious, related, and severe enough that the
reviewer's question is causality rather than triage.

The discontinuation leg is only as good as the source column.
`strActionCol` names the AE action-taken field; when it is `NULL` or
absent from the data, that leg is inactive and the returned frame
records `ActionColumnPresent = FALSE`, so a study missing the column
reports the gap rather than silently scoring as though no participant
ever discontinued.

## Examples

``` r
dfAE <- data.frame(
  subjid = c("S1", "S1", "S2"),
  aeser = c("Y", "N", "N"),
  aerel = c("Y", "Y", "Y"),
  aetoxgr = c(4, 1, 2)
)
Input_SafetyAE(dfAE)
#>   SubjectID GroupID GroupLevel Numerator Denominator Metric AECount
#> 1        S1      S1    Subject         3           1      3       2
#> 2        S2      S2    Subject         1           1      1       1
#>   SeriousCount RelatedCount SeriousAndRelated Discontinuation
#> 1            1            2              TRUE           FALSE
#> 2            0            1             FALSE           FALSE
#>   ActionColumnPresent
#> 1               FALSE
#> 2               FALSE
```
