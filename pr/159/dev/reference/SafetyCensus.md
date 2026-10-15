# Study census, exposure and data coverage for a safety overview

The denominators a safety reader needs *before* any event count means
anything: how many participants there are, how many are on treatment,
how much person-time has accrued, who has left the study and why, and —
the one most often missing — how completely the safety data itself has
been collected.

## Usage

``` r
SafetyCensus(
  dfSubjects,
  dfLabs = NULL,
  dfECG = NULL,
  dfAE = NULL,
  dfDisposition = NULL,
  strIDCol = "subjid",
  strArmCol = "arm",
  strTimeOnStudyCol = "timeonstudy",
  strTimeOnTreatmentCol = "timeontreatment",
  strLabVisitCol = "visnam",
  strLabVisitNumCol = "visnum",
  strECGVisitCol = "visnam",
  strECGVisitNumCol = "visnum",
  strCompleteCol = "compyn",
  strReasonCol = "compreas",
  chrDeathValues = c("DEATH", "DIED")
)
```

## Arguments

- dfSubjects:

  `data.frame` Subject-level domain, one row per participant.

- dfLabs:

  `data.frame` or `NULL` Long-format lab results, for lab coverage by
  visit.

- dfECG:

  `data.frame` or `NULL` Long-format ECG records, for ECG coverage by
  visit.

- dfAE:

  `data.frame` or `NULL` Adverse events, for the AE reporting rate.

- dfDisposition:

  `data.frame` or `NULL` Study-completion domain, for disposition and
  deaths.

- strIDCol:

  `character` Participant ID column, shared by every domain. Default:
  `"subjid"`.

- strArmCol:

  `character` Treatment arm column in `dfSubjects`; used only to count
  randomised participants, never to split a figure. Default: `"arm"`.

- strTimeOnStudyCol, strTimeOnTreatmentCol:

  `character` Person-time columns in `dfSubjects`, in days. Defaults:
  `"timeonstudy"`, `"timeontreatment"`.

- strLabVisitCol, strLabVisitNumCol:

  `character` Visit label and visit number columns in `dfLabs`.
  Defaults: `"visnam"`, `"visnum"`.

- strECGVisitCol, strECGVisitNumCol:

  `character` Visit label and visit number columns in `dfECG`. Defaults:
  `"visnam"`, `"visnum"`.

- strCompleteCol, strReasonCol:

  `character` Completion flag and reason columns in `dfDisposition`.
  Defaults: `"compyn"`, `"compreas"`.

- chrDeathValues:

  `character` Values of the disposition reason column read as death.
  Default: `c("DEATH", "DIED")`.

## Value

`list` with three data.frames:

- `Census` — one row per named figure (`Label`, `Value`, `Denominator`,
  `Group`), the study's denominators and exposure;

- `Coverage` — one row per domain per visit (`Domain`, `Visit`,
  `VisitNum`, `Participants`, `Expected`), data availability;

- `Disposition` — one row per disposition state (`State`,
  `Participants`).

## Details

Coverage is not decoration. A low event rate at a visit where 40% of
participants have no lab result is not reassurance, and the only way to
tell those two situations apart is to publish the denominator beside the
count. `Coverage` therefore reports, per visit, how many participants
have at least one result against how many are expected.

Every figure is **pooled across treatment arms**. A study-team safety
view is a blinded view, and FDA guidance treats even coded arms (A/B/C)
as unblinded data, so no arm split is produced here.

## Examples

``` r
dfSubjects <- data.frame(
  subjid = c("S1", "S2", "S3"),
  arm = c("A", "A", NA),
  timeonstudy = c(120, 90, 30),
  timeontreatment = c(110, 80, 0)
)
SafetyCensus(dfSubjects)$Census
#>                                     Label Value Denominator     Group
#> 1                   Enrolled participants   3.0          NA    Census
#> 2                    Randomised to an arm   2.0           3    Census
#> 3                     Received study drug   2.0           3    Census
#> 4                                  Deaths    NA           3    Census
#> 5                   Person-years on study   0.7          NA  Exposure
#> 6               Person-years on treatment   0.5          NA  Exposure
#> 7                Median days on treatment  95.0          NA  Exposure
#> 8          Participants with a lab result    NA           3 Follow-up
#> 9                Participants with an ECG    NA           3 Follow-up
#> 10        Participants with a reported AE    NA           3 Follow-up
#> 11 Participants with a disposition record    NA           3 Follow-up
```
