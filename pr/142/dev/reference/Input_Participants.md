# Study-level count of the participants a domain names

The numerator step behind most of the census metrics: `saf0005` and
`saf0007`, `saf0010` through `saf0015`. It counts the participants a
mapped domain names — optionally only those whose column matches a
value, or whose column records anything at all — anchored to the
enrolled population, and hands
[`gsm.core::Transform_Rate()`](https://rdrr.io/pkg/gsm.core/man/Transform_Rate.html)
an ordinary `analyticsInput` frame.

## Usage

``` r
Input_Participants(
  dfDomain,
  dfSubjects,
  strIDCol = "subjid",
  strFilterCol = NULL,
  strFilterValues = NULL,
  strDomainName = "dfDomain",
  strGroupCol = "studyid",
  strGroupLevel = "Study"
)
```

## Arguments

- dfDomain:

  `data.frame` Mapped domain to count participants from.

- dfSubjects:

  `data.frame` Mapped subject-level domain, the enrolled population —
  `gsm.mapping`'s `Mapped_SUBJ`. It is both the anchor and the
  denominator.

- strIDCol:

  `character` Participant ID column, shared by both domains. Default:
  `"subjid"`.

- strFilterCol:

  `character` or `NULL` Column of `dfDomain` that decides whether a
  participant counts. `NULL` (the default) counts every participant the
  domain names.

- strFilterValues:

  `character` or `NULL` Values of `strFilterCol` that count, compared
  without regard to case or surrounding space. Several are written
  comma-separated — `"Y, N"` — following the ecosystem's convention for
  a multi-valued meta scalar. `NULL` (the default) counts a participant
  whose `strFilterCol` records *anything*: not missing, not blank.

- strDomainName:

  `character` Name of the mapped domain, used in the errors a reader has
  to act on. Default: `"dfDomain"`.

- strGroupCol:

  `character` Grouping column in `dfSubjects`. Default: `"studyid"` —
  the study level this release publishes.

- strGroupLevel:

  `character` Group level to record. Default: `"Study"`. Moving a metric
  to site level is this argument plus `strGroupCol`, not a different
  metric.

## Value

`data.frame` conforming to `analyticsInput` (`SubjectID`, `GroupID`,
`GroupLevel`, `Numerator`, `Denominator`, `Metric`), one row per
enrolled participant — or zero rows when nothing was measured.

## Details

One step, eight metrics. The differences between "participants with a
lab result" and "participants who completed" are which domain is read,
which column is looked at and which value is matched, and all three are
declared in the metric definition. Writing the arithmetic once is
deliberate: eight hand-written counting steps are eight chances to write
one of them wrong, which is the defect this rebuild exists to remove.

## Absent, empty, and zero are three different answers

|        |                                        |                           |
|--------|----------------------------------------|---------------------------|
| State  | What the study said                    | What this returns         |
| Absent | no domain, or no declared column in it | an **error**              |
| Empty  | a domain with no rows at all           | **no row**, and a warning |
| Zero   | a populated domain naming nobody       | a row reading **0**       |

A zero is a measurement — the domain ran and the answer was none.
Absence is not a measurement, and neither is a table with nothing in it,
so neither is allowed to render as a reassuring zero.
[`gsm.core::CheckSpec()`](https://rdrr.io/pkg/gsm.core/man/CheckSpec.html)
only *warns* on a declared column that is missing (it errors only on a
missing data.frame), so the column check lives here for the guarantee to
hold.

A subject domain with no rows is a fourth state: no denominator at all.
Nothing is published, and a warning says why.

## Counted once, and only if enrolled

Two rules the D0023 design makes standing, applied here rather than
trusted: the domain is reduced to one row per participant before
counting, so a duplicated row cannot inflate the figure; and the count
is anchored to `dfSubjects`, so a participant identifier that appears in
the domain but not in the enrolled population is never counted and the
numerator can never exceed its denominator.

## Examples

``` r
dfSubjects <- data.frame(subjid = c("S1", "S2"), studyid = "AA-AA-000-0000")
dfDisposition <- data.frame(subjid = c("S1", "S2"), compyn = c("Y", "N"))

# Participants with a disposition record
Input_Participants(dfDisposition, dfSubjects)
#>   SubjectID        GroupID GroupLevel Numerator Denominator Metric
#> 1        S1 AA-AA-000-0000      Study         1           1      1
#> 2        S2 AA-AA-000-0000      Study         1           1      1

# Participants who completed
Input_Participants(
  dfDisposition, dfSubjects,
  strFilterCol = "compyn", strFilterValues = "Y"
)
#>   SubjectID        GroupID GroupLevel Numerator Denominator Metric
#> 1        S1 AA-AA-000-0000      Study         1           1      1
#> 2        S2 AA-AA-000-0000      Study         0           1      0
```
