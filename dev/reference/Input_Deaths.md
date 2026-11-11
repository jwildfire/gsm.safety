# Study-level count of participants who died

The numerator step behind `saf0004`, the first of the census metrics. It
counts the participants a study's **death domain** records as having
died, anchored to the enrolled population, and hands
[`gsm.core::Transform_Rate()`](https://gilead-public.github.io/gsm.core/reference/Transform_Rate.html)
an ordinary `analyticsInput` frame.

## Usage

``` r
Input_Deaths(
  dfDeath,
  dfSubjects,
  dfStudyCompletion = NULL,
  strReasonCol = "compreas",
  strDeathReason = "Death",
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

- dfStudyCompletion:

  `data.frame` or `NULL` Mapped study-completion domain, one row per
  completion record — `gsm.mapping`'s `Mapped_STUDCOMP`. When given, a
  participant whose `strReasonCol` is `strDeathReason` in any case and
  with surrounding spaces ignored counts as died. Default: `NULL`, the
  death domain alone, which the log says. A single string, which is what
  a workflow step receives when the domain it names was not supplied, is
  read as `NULL`.

- strReasonCol:

  `character` Discontinuation-reason column of `dfStudyCompletion`.
  Default: `"compreas"`.

- strDeathReason:

  `character` The reason, or reasons, that mean death, compared
  case-insensitively. Default: `"Death"`.

- strIDCol:

  `character` Participant ID column, shared by every domain. Default:
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
enrolled participant — or zero rows when both sources are empty.

## Details

A participant has died if the death domain marks them, or, when
`dfStudyCompletion` is given, if their discontinuation reason is death
in any case (`"Death"`, `"DEATH"`, `"death"`). `Mapped_Death` is meant
to be that union already
([`gsm.mapping::complete_death()`](https://gilead-public.github.io/gsm.mapping/reference/complete_death.html)),
but gsm.mapping 1.2.0 compares the reason against `"DEATH"` exactly, and
a study that writes `"Death"` loses those participants (#168). Reading
the reason here keeps the count independent of how the mapping spells
it. The reason has to equal the word: "Death of a relative" is not a
death.

## Absent, empty, and zero are three different answers

The defect this metric replaces reported **one** death on a study whose
records hold thirteen, by text-matching a discontinuation reason. The
defect beside it reported **zero** where a column was missing. So the
three states are kept apart deliberately:

|  |  |  |
|----|----|----|
| State | What the study said | What this returns |
| Absent | no death domain, or no `death` / ID column in it | an **error** |
| Empty | a death domain with no rows, and no completion domain with rows | **no row**, and a warning |
| Zero | a populated source marking nobody as died | a row reading **0** |

A zero is a measurement — the domain ran and the answer was none.
Absence is not a measurement, and neither is a table with nothing in it,
so neither is allowed to render as a reassuring zero. Note that
[`gsm.core::CheckSpec()`](https://gilead-public.github.io/gsm.core/reference/CheckSpec.html)
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
#> ℹ No study-completion domain was supplied, so the death count reads the death domain alone.
#>   SubjectID        GroupID GroupLevel Numerator Denominator Metric
#> 1        S1 AA-AA-000-0000      Study         1           1      1
#> 2        S2 AA-AA-000-0000      Study         0           1      0
```
