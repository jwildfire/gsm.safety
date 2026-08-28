# Assemble a participant-level `analyticsInput` frame

The gsm analytics contract is `analyticsInput` (`SubjectID`, `GroupID`,
`GroupLevel`, `Numerator`, `Denominator`, `Metric`) in,
`analyticsSummary` out. gsm.safety's metrics are participant-level —
`GroupLevel: Subject`, with `GroupID` equal to `SubjectID`, following
the `pat0015.yaml` precedent in gsm.kri — and each one scores a
participant with an ordinal *tier* rather than a rate.

## Usage

``` r
MakeParticipantInput(
  dfEvidence,
  strIDCol = "subjid",
  strGroupLevel = "Subject"
)
```

## Arguments

- dfEvidence:

  `data.frame` One row per assessed participant, carrying at least the
  participant ID column and a `Numerator` column holding the tier.

- strIDCol:

  `character` Name of the participant ID column in `dfEvidence`.
  Default: `"subjid"`.

- strGroupLevel:

  `character` Group level to record. Default: `"Subject"`.

## Value

`data.frame` with `SubjectID`, `GroupID`, `GroupLevel`, `Numerator`,
`Denominator`, `Metric`, followed by every other column of `dfEvidence`.

## Details

Every metric therefore emits one row per **assessed** participant with
`Numerator` = the tier and `Denominator` = 1, so
[`gsm.core::Transform_Rate()`](https://rdrr.io/pkg/gsm.core/man/Transform_Rate.html)
carries the tier through to `Metric` unchanged and
[`gsm.core::Analyze_Identity()`](https://rdrr.io/pkg/gsm.core/man/Analyze_Identity.html)
copies it to `Score`. A participant with no assessable data gets no row
at all: "not assessed" is absence, never a reassuring zero. The row
count is the metric's own coverage denominator.

Evidence columns (peak values, counts, the terms behind a flag) are
carried through on this frame. `Transform_Rate()` summarises them away,
but the unsummarised `Analysis_Input` is saved beside every other step's
output, so the numbers behind a flag stay one file away from the flag
itself.
