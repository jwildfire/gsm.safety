# Study census, exposure and follow-up for a safety overview

The denominators a safety reader needs *before* any event count means
anything: how many participants there are, how many were randomised, how
many were dosed, how much person-time has accrued, and how many of them
the study's safety domains actually name.

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
  chrDeathValues = c("DEATH", "DIED"),
  dfDeath = NULL,
  dfRandomization = NULL,
  strGroupCol = "studyid"
)
```

## Arguments

- dfSubjects:

  `data.frame` Mapped subject-level domain, the enrolled population —
  `gsm.mapping`'s `Mapped_SUBJ`. It is both the anchor and the
  denominator of every other figure.

- dfLabs:

  `data.frame` or `NULL` Mapped lab domain (`Mapped_LB`).

- dfECG:

  `data.frame` or `NULL` Mapped ECG domain (`Mapped_EG`).

- dfAE:

  `data.frame` or `NULL` Mapped adverse-event domain (`Mapped_AE`).

- dfDisposition:

  `data.frame` or `NULL` Mapped study-completion domain
  (`Mapped_STUDCOMP`).

- strIDCol:

  `character` Participant ID column, shared by every domain. Default:
  `"subjid"`. A domain keyed on another name is renamed to the
  mapped-domain convention before the metrics read it.

- strArmCol, strTimeOnStudyCol, strTimeOnTreatmentCol, strLabVisitCol,
  strLabVisitNumCol, strECGVisitCol, strECGVisitNumCol, strCompleteCol,
  strReasonCol, chrDeathValues:

  **Deprecated and ignored.** Every census metric declares the columns
  it reads in its own definition, so this function no longer takes a
  column name from its caller. Supplying one warns and changes nothing;
  they are kept so that existing calls keep working (D0023.5, approved).

- dfDeath:

  `data.frame` or `NULL` Mapped death domain (`Mapped_Death`) —
  `gsm.mapping`'s union of the death domain and the study-completion
  domain's discontinuation reason. Without it the death count is absent
  rather than read from a reason column, which is how it was wrong
  before.

- dfRandomization:

  `data.frame` or `NULL` Mapped randomisation domain
  (`Mapped_Randomization`). Counting that a participant was randomised
  without reading what they were randomised to is what keeps this figure
  out of the treatment-arm column.

- strGroupCol:

  `character` Study identifier column in `dfSubjects`, which groups the
  metrics. Default: `"studyid"`. It does not appear in what this
  function returns, so a subject domain without one still counts, with a
  warning.

## Value

`list` with three data.frames, the shape it has always returned:

- `Census` — one row per named figure (`Label`, `Value`, `Denominator`,
  `Group`), grouped as `Census`, `Exposure` and `Follow-up`;

- `Coverage` — `Domain`, `Visit`, `VisitNum`, `Participants`,
  `Expected`; no rows until the coverage metric lands (#58);

- `Disposition` — one row per published disposition state (`State`,
  `Participants`), largest first.

## Details

Every figure is **pooled across treatment arms**. A study-team safety
view is a blinded view, and FDA guidance treats even coded arms (A/B/C)
as unblinded data, so no arm split is produced here.

## This function counts nothing

It runs the census metrics in `inst/workflow/2_metrics/` over the
domains it is given, then reads what they published through the census
report's own helpers
([`Report_CensusFigures()`](https://jwildfire.github.io/gsm.safety/dev/reference/Report_CensusFigures.md)).
Every number it returns is a `Numerator` a metric published, beside the
`Denominator` that same metric published.

That is the point of the rebuild rather than a detail of it. Until
v1.3.0 this function did its own arithmetic, and four of the figures it
published were wrong — most of all the death count, which matched the
text of a discontinuation reason, never read the death domain, and
counted participants who were never enrolled. A figure counted in two
places can disagree with itself; there is one counting lane now, and it
is the metric. What each metric measures, and what it was measured
against, is recorded in `inst/qualification/`.

## Absent, empty, and zero are three different answers

A domain that is not supplied, or that a metric could not read, leaves
its figure **absent** — `NA`, with a warning naming the domain. A domain
with no rows has measured nothing and is also absent. A populated domain
that names nobody publishes **zero**, which is a measurement. Only the
last of the three is a number, and none of them is allowed to read as
another.

## What moved out of this function in v1.3.0

Three things it used to return are not returned any more, because no
metric publishes them and computing them here would be the second
counting lane this rebuild exists to remove:

- **Median days on treatment** — wants an averaging step in the metric
  layer; see
  [gsm.safety#61](https://github.com/jwildfire/gsm.safety/issues/61).

- **Visit-level data coverage** — the thirteenth census figure, carried
  to [\#58](https://github.com/jwildfire/gsm.safety/issues/58):
  `gsm.mapping`'s lab domain carries no visit column under the standard
  mapping. `Coverage` is returned with its columns and no rows.

- **Disposition states with no metric** — `Ongoing`, the
  `Discontinued - <reason>` breakdown built from free text, and
  `Not in the disposition domain`, which was a subtraction.
  `Disposition` now holds the states the disposition metrics publish:
  completed, discontinued and died.

## Examples

``` r
dfSubjects <- data.frame(
  subjid = c("S1", "S2", "S3"),
  studyid = "AA-AA-000-0000",
  firstdosedate = as.Date(c("2020-01-01", "2020-01-02", NA)),
  timeonstudy = c(120L, 90L, 30L),
  timeontreatment = c(110L, 80L, 0L)
)
dfDeath <- data.frame(subjid = "S2", death = TRUE)

suppressWarnings(SafetyCensus(dfSubjects, dfDeath = dfDeath)$Census)
#> [INFO] Initializing `Analysis_saf0004` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 6: `gsm.safety::Input_Deaths`
#> [INFO] Evaluating 4 parameter(s) for `gsm.safety::Input_Deaths`
#> [INFO] dfDeath = Mapped_Death: Passing lData$Mapped_Death.
#> [INFO] dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] strGroupCol = GroupCol: Passing lMeta$GroupCol.
#> [INFO] strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> [INFO] Calling `gsm.safety::Input_Deaths`
#> [INFO] 3x6 data.frame saved as `lData$Analysis_Input`.
#> [INFO] Workflow Step 2 of 6: `gsm.core::Transform_Rate`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Transform_Rate`
#> [INFO] dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Calling `gsm.core::Transform_Rate`
#> [INFO] 1x5 data.frame saved as `lData$Analysis_Transformed`.
#> [INFO] Workflow Step 3 of 6: `gsm.core::Analyze_Identity`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::Analyze_Identity`
#> [INFO] dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] strValueCol = Score: Passing lMeta$Score.
#> [INFO] Calling `gsm.core::Analyze_Identity`
#> `Score` column created from `Numerator`.
#> [INFO] 1x6 data.frame saved as `lData$Analysis_Analyzed`.
#> [INFO] Workflow Step 4 of 6: `gsm.safety::Flag_None`
#> [INFO] Evaluating 1 parameter(s) for `gsm.safety::Flag_None`
#> [INFO] dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Calling `gsm.safety::Flag_None`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Flagged`.
#> [INFO] Workflow Step 5 of 6: `gsm.core::Summarize`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Summarize`
#> [INFO] dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Calling `gsm.core::Summarize`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Summary`.
#> [INFO] Workflow Step 6 of 6: `list`
#> [INFO] Evaluating 6 parameter(s) for `list`
#> [INFO] ID = ID: Passing lMeta$ID.
#> [INFO] Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> [INFO] Calling `list`
#> [INFO] list of length 6 saved as `lData$lAnalysis`.
#> [INFO] Returning results from final step: list of length 6`.
#> [INFO] Completed `Analysis_saf0004` Workflow
#> [INFO] Initializing `Analysis_saf0005` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 6: `gsm.safety::Input_Participants`
#> [INFO] Evaluating 5 parameter(s) for `gsm.safety::Input_Participants`
#> [INFO] dfDomain = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] strDomainName = Domain: Passing lMeta$Domain.
#> [INFO] strGroupCol = GroupCol: Passing lMeta$GroupCol.
#> [INFO] strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> [INFO] Calling `gsm.safety::Input_Participants`
#> [INFO] 3x6 data.frame saved as `lData$Analysis_Input`.
#> [INFO] Workflow Step 2 of 6: `gsm.core::Transform_Rate`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Transform_Rate`
#> [INFO] dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Calling `gsm.core::Transform_Rate`
#> [INFO] 1x5 data.frame saved as `lData$Analysis_Transformed`.
#> [INFO] Workflow Step 3 of 6: `gsm.core::Analyze_Identity`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::Analyze_Identity`
#> [INFO] dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] strValueCol = Score: Passing lMeta$Score.
#> [INFO] Calling `gsm.core::Analyze_Identity`
#> `Score` column created from `Numerator`.
#> [INFO] 1x6 data.frame saved as `lData$Analysis_Analyzed`.
#> [INFO] Workflow Step 4 of 6: `gsm.safety::Flag_None`
#> [INFO] Evaluating 1 parameter(s) for `gsm.safety::Flag_None`
#> [INFO] dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Calling `gsm.safety::Flag_None`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Flagged`.
#> [INFO] Workflow Step 5 of 6: `gsm.core::Summarize`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Summarize`
#> [INFO] dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Calling `gsm.core::Summarize`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Summary`.
#> [INFO] Workflow Step 6 of 6: `list`
#> [INFO] Evaluating 6 parameter(s) for `list`
#> [INFO] ID = ID: Passing lMeta$ID.
#> [INFO] Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> [INFO] Calling `list`
#> [INFO] list of length 6 saved as `lData$lAnalysis`.
#> [INFO] Returning results from final step: list of length 6`.
#> [INFO] Completed `Analysis_saf0005` Workflow
#> [INFO] Initializing `Analysis_saf0007` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 6: `gsm.safety::Input_Participants`
#> [INFO] Evaluating 6 parameter(s) for `gsm.safety::Input_Participants`
#> [INFO] dfDomain = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] strFilterCol = FilterCol: Passing lMeta$FilterCol.
#> [INFO] strDomainName = Domain: Passing lMeta$Domain.
#> [INFO] strGroupCol = GroupCol: Passing lMeta$GroupCol.
#> [INFO] strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> [INFO] Calling `gsm.safety::Input_Participants`
#> [INFO] 3x6 data.frame saved as `lData$Analysis_Input`.
#> [INFO] Workflow Step 2 of 6: `gsm.core::Transform_Rate`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Transform_Rate`
#> [INFO] dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Calling `gsm.core::Transform_Rate`
#> [INFO] 1x5 data.frame saved as `lData$Analysis_Transformed`.
#> [INFO] Workflow Step 3 of 6: `gsm.core::Analyze_Identity`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::Analyze_Identity`
#> [INFO] dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] strValueCol = Score: Passing lMeta$Score.
#> [INFO] Calling `gsm.core::Analyze_Identity`
#> `Score` column created from `Numerator`.
#> [INFO] 1x6 data.frame saved as `lData$Analysis_Analyzed`.
#> [INFO] Workflow Step 4 of 6: `gsm.safety::Flag_None`
#> [INFO] Evaluating 1 parameter(s) for `gsm.safety::Flag_None`
#> [INFO] dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Calling `gsm.safety::Flag_None`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Flagged`.
#> [INFO] Workflow Step 5 of 6: `gsm.core::Summarize`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Summarize`
#> [INFO] dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Calling `gsm.core::Summarize`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Summary`.
#> [INFO] Workflow Step 6 of 6: `list`
#> [INFO] Evaluating 6 parameter(s) for `list`
#> [INFO] ID = ID: Passing lMeta$ID.
#> [INFO] Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> [INFO] Calling `list`
#> [INFO] list of length 6 saved as `lData$lAnalysis`.
#> [INFO] Returning results from final step: list of length 6`.
#> [INFO] Completed `Analysis_saf0007` Workflow
#> [INFO] Initializing `Analysis_saf0008` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 6: `gsm.safety::Input_ParticipantDays`
#> [INFO] Evaluating 5 parameter(s) for `gsm.safety::Input_ParticipantDays`
#> [INFO] dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] strDayCol = DayCol: Passing lMeta$DayCol.
#> [INFO] strDomainName = Domain: Passing lMeta$Domain.
#> [INFO] strGroupCol = GroupCol: Passing lMeta$GroupCol.
#> [INFO] strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> [INFO] Calling `gsm.safety::Input_ParticipantDays`
#> [INFO] 3x6 data.frame saved as `lData$Analysis_Input`.
#> [INFO] Workflow Step 2 of 6: `gsm.core::Transform_Rate`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Transform_Rate`
#> [INFO] dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Calling `gsm.core::Transform_Rate`
#> [INFO] 1x5 data.frame saved as `lData$Analysis_Transformed`.
#> [INFO] Workflow Step 3 of 6: `gsm.core::Analyze_Identity`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::Analyze_Identity`
#> [INFO] dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] strValueCol = Score: Passing lMeta$Score.
#> [INFO] Calling `gsm.core::Analyze_Identity`
#> `Score` column created from `Numerator`.
#> [INFO] 1x6 data.frame saved as `lData$Analysis_Analyzed`.
#> [INFO] Workflow Step 4 of 6: `gsm.safety::Flag_None`
#> [INFO] Evaluating 1 parameter(s) for `gsm.safety::Flag_None`
#> [INFO] dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Calling `gsm.safety::Flag_None`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Flagged`.
#> [INFO] Workflow Step 5 of 6: `gsm.core::Summarize`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Summarize`
#> [INFO] dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Calling `gsm.core::Summarize`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Summary`.
#> [INFO] Workflow Step 6 of 6: `list`
#> [INFO] Evaluating 6 parameter(s) for `list`
#> [INFO] ID = ID: Passing lMeta$ID.
#> [INFO] Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> [INFO] Calling `list`
#> [INFO] list of length 6 saved as `lData$lAnalysis`.
#> [INFO] Returning results from final step: list of length 6`.
#> [INFO] Completed `Analysis_saf0008` Workflow
#> [INFO] Initializing `Analysis_saf0009` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 6: `gsm.safety::Input_ParticipantDays`
#> [INFO] Evaluating 5 parameter(s) for `gsm.safety::Input_ParticipantDays`
#> [INFO] dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] strDayCol = DayCol: Passing lMeta$DayCol.
#> [INFO] strDomainName = Domain: Passing lMeta$Domain.
#> [INFO] strGroupCol = GroupCol: Passing lMeta$GroupCol.
#> [INFO] strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> [INFO] Calling `gsm.safety::Input_ParticipantDays`
#> [INFO] 3x6 data.frame saved as `lData$Analysis_Input`.
#> [INFO] Workflow Step 2 of 6: `gsm.core::Transform_Rate`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Transform_Rate`
#> [INFO] dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Calling `gsm.core::Transform_Rate`
#> [INFO] 1x5 data.frame saved as `lData$Analysis_Transformed`.
#> [INFO] Workflow Step 3 of 6: `gsm.core::Analyze_Identity`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::Analyze_Identity`
#> [INFO] dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] strValueCol = Score: Passing lMeta$Score.
#> [INFO] Calling `gsm.core::Analyze_Identity`
#> `Score` column created from `Numerator`.
#> [INFO] 1x6 data.frame saved as `lData$Analysis_Analyzed`.
#> [INFO] Workflow Step 4 of 6: `gsm.safety::Flag_None`
#> [INFO] Evaluating 1 parameter(s) for `gsm.safety::Flag_None`
#> [INFO] dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Calling `gsm.safety::Flag_None`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Flagged`.
#> [INFO] Workflow Step 5 of 6: `gsm.core::Summarize`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Summarize`
#> [INFO] dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Calling `gsm.core::Summarize`
#> [INFO] 1x7 data.frame saved as `lData$Analysis_Summary`.
#> [INFO] Workflow Step 6 of 6: `list`
#> [INFO] Evaluating 6 parameter(s) for `list`
#> [INFO] ID = ID: Passing lMeta$ID.
#> [INFO] Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> [INFO] Calling `list`
#> [INFO] list of length 6 saved as `lData$lAnalysis`.
#> [INFO] Returning results from final step: list of length 6`.
#> [INFO] Completed `Analysis_saf0009` Workflow
#>                                     Label Value Denominator     Group
#> 1                   Enrolled participants   3.0          NA    Census
#> 2                    Randomised to an arm    NA          NA    Census
#> 3                     Received study drug   2.0           3    Census
#> 4                                  Deaths   1.0           3    Census
#> 5                   Person-years on study   0.7          NA  Exposure
#> 6               Person-years on treatment   0.5          NA  Exposure
#> 7          Participants with a lab result    NA          NA Follow-up
#> 8                Participants with an ECG    NA          NA Follow-up
#> 9         Participants with a reported AE    NA          NA Follow-up
#> 10 Participants with a disposition record    NA          NA Follow-up
```
