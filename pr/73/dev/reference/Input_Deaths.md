# Study-level count of participants who died

The numerator step behind `saf0004`, the first of the census metrics. It
counts the participants a study's **death domain** records as having
died, anchored to the enrolled population, and hands
[`gsm.core::Transform_Rate()`](https://rdrr.io/pkg/gsm.core/man/Transform_Rate.html)
an ordinary `analyticsInput` frame.

## Usage

``` r
Input_Deaths(
  dfDeath,
  dfSubjects,
  strIDCol = "subjid",
  strDeathCol = "death",
  strGroupCol = "studyid",
  strGroupLevel = "Study"
)
```

## Arguments

- dfDeath:

  `data.frame` Mapped death domain, one row per death record —
  `gsm.mapping`'s `Mapped_Death`. Rows it carries for other reasons (a
  progressive-disease date, say) have `death` missing rather than
  `TRUE`.

- dfSubjects:

  `data.frame` Mapped subject-level domain, the enrolled population —
  `gsm.mapping`'s `Mapped_SUBJ`. It is both the anchor and the
  denominator.

- strIDCol:

  `character` Participant ID column, shared by both domains. Default:
  `"subjid"`.

- strDeathCol:

  `character` Column of `dfDeath` marking a death. Read as true when
  logical `TRUE`, a non-zero number, or one of `"TRUE"`, `"T"`, `"Y"`,
  `"YES"`, `"1"`. Default: `"death"`.

- strGroupCol:

  `character` Grouping column in `dfSubjects`. Default: `"studyid"` —
  the study level this release publishes.

- strGroupLevel:

  `character` Group level to record. Default: `"Study"`. Moving the
  metric to site level is this argument plus `strGroupCol`, not a
  different metric.

## Value

`data.frame` conforming to `analyticsInput` (`SubjectID`, `GroupID`,
`GroupLevel`, `Numerator`, `Denominator`, `Metric`), one row per
enrolled participant — or zero rows when the death domain is empty.

## Details

No clinical definition of death is written here. `Mapped_Death` is
gsm.mapping's own union of the death domain and the study-completion
domain's discontinuation reason
([`gsm.mapping::complete_death()`](https://gilead-public.github.io/gsm.mapping/reference/complete_death.html));
this function counts the participants that union marks, and nothing
else.

## Absent, empty, and zero are three different answers

The defect this metric replaces reported **one** death on a study whose
records hold thirteen, by text-matching a discontinuation reason. The
defect beside it reported **zero** where a column was missing. So the
three states are kept apart deliberately:

|  |  |  |
|----|----|----|
| State | What the study said | What this returns |
| Absent | no death domain, or no `death` / ID column in it | an **error** |
| Empty | a death domain with no rows at all | **no row**, and a warning |
| Zero | a populated death domain marking nobody as died | a row reading **0** |

A zero is a measurement — the domain ran and the answer was none.
Absence is not a measurement, and neither is a table with nothing in it,
so neither is allowed to render as a reassuring zero. Note that
[`gsm.core::CheckSpec()`](https://rdrr.io/pkg/gsm.core/man/CheckSpec.html)
only *warns* on a declared column that is missing (it errors only on a
missing data.frame), so the column check has to live here for the
guarantee to hold.

## Counted once, and only if enrolled

Two rules the D0023 design makes standing, applied here rather than
trusted: the death domain is reduced to one row per participant before
counting, so a duplicated row cannot inflate the figure; and the count
is anchored to `dfSubjects`, so a participant identifier that appears in
the death domain but not in the enrolled population is never counted and
the numerator can never exceed its denominator.

## Examples

``` r
dfSubjects <- data.frame(subjid = c("S1", "S2"), studyid = "AA-AA-000-0000")
dfDeath <- data.frame(subjid = c("S1", "S2"), death = c(TRUE, NA))
Input_Deaths(dfDeath, dfSubjects)
#>   SubjectID        GroupID GroupLevel Numerator Denominator Metric
#> 1        S1 AA-AA-000-0000      Study         1           1      1
#> 2        S2 AA-AA-000-0000      Study         0           1      0
```
