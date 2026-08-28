# Study-level total of participant-days

The numerator step behind `saf0008` and `saf0009`, the two person-time
figures. It sums a day column of the enrolled population — `timeonstudy`
or `timeontreatment` — and hands
[`gsm.core::Transform_Rate()`](https://rdrr.io/pkg/gsm.core/man/Transform_Rate.html)
an ordinary `analyticsInput` frame whose `Numerator` is the total days
and whose `Denominator` is the participants who contributed them.

## Usage

``` r
Input_ParticipantDays(
  dfSubjects,
  strDayCol,
  strIDCol = "subjid",
  strDomainName = "dfSubjects",
  strGroupCol = "studyid",
  strGroupLevel = "Study"
)
```

## Arguments

- dfSubjects:

  `data.frame` Mapped subject-level domain, the enrolled population —
  `gsm.mapping`'s `Mapped_SUBJ`.

- strDayCol:

  `character` Column of `dfSubjects` holding person-time in days, e.g.
  `"timeonstudy"` or `"timeontreatment"`.

- strIDCol:

  `character` Participant ID column. Default: `"subjid"`.

- strDomainName:

  `character` Name of the mapped domain, used in the errors a reader has
  to act on. Default: `"dfSubjects"`.

- strGroupCol:

  `character` Grouping column in `dfSubjects`. Default: `"studyid"`.

- strGroupLevel:

  `character` Group level to record. Default: `"Study"`.

## Value

`data.frame` conforming to `analyticsInput` (`SubjectID`, `GroupID`,
`GroupLevel`, `Numerator`, `Denominator`, `Metric`), one row per
contributing participant — or zero rows when nothing was measured.

## Days, not years

The figure published is the number actually summed, in the unit the
subject domain records it in. The census report is where person-years
are presented, and it divides. A metric that published years would be
publishing a figure nothing in the pipeline can check against the domain
it came from.

## Missing person-time is not zero days

`Numerator / Denominator` is the mean days per participant, so a
participant whose person-time was never recorded cannot stay in one side
of the fraction and leave the other: counting them as zero days would
understate the total and inflate the denominator at once. They leave
both, and a warning names them. A *recorded* zero is different — it is a
measurement, and stays.

Negative person-time is treated the same way. It is not a duration, so
it is not summed, and the warning says how many participants it happened
to.

## Examples

``` r
dfSubjects <- data.frame(
  subjid = c("S1", "S2"),
  studyid = "AA-AA-000-0000",
  timeonstudy = c(120, 90)
)
Input_ParticipantDays(dfSubjects, "timeonstudy")
#>   SubjectID        GroupID GroupLevel Numerator Denominator Metric
#> 1        S1 AA-AA-000-0000      Study       120           1    120
#> 2        S2 AA-AA-000-0000      Study        90           1     90
```
