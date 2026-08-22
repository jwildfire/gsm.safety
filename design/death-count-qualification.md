# Qualifying the death count (`saf0004`)

Recorded 2026-08-21 · [gsm.safety#56](https://github.com/jwildfire/gsm.safety/issues/56) ·
[obot.roadmap#274](https://github.com/jwildfire/obot.roadmap/issues/274) ·
[D0023](https://jwildfire.github.io/obot.roadmap/reports/decisions/2026-08-20-safety-census-rebuild/)

Passing tests are not the check. The D0023 design says so directly: a test
asserting that the code does what the code does would not have caught one of
the defects this rebuild exists to fix. So the death count is measured twice on
the same study, by two routes that share no code, and the result is recorded
here.

## The two routes

- **Route B — the records, read directly.** Base R over
  `gsm.core::lSource`: the death domain and the study-completion domain's
  discontinuation reason, unioned by participant, intersected with the enrolled
  population. No mapping package, no metric, no gsm helper.
- **Route A — the pipeline.** The standard `gsm.mapping` mapping into
  `Mapped_Death` and `Mapped_SUBJ`, then the `saf0004` workflow end to end.

Reproduce either with:

```bash
Rscript tools/qualify-death-count.R
```

The same two routes run in the suite as
`tests/testthat/test-qualification-death-count.R`, so a change in the bundled
study or in the mapping is loud rather than silent.

## What was measured

Bundled study `AA-AA-000-0000`, from `gsm.core::lSource`.
`gsm.core` 1.2.0, `gsm.mapping` 1.1.3, R 4.3.

| Figure | Count |
|---|---|
| Participants in `Raw_SUBJ` | 1000 |
| Enrolled (`enrollyn == "Y"`) — the denominator | 760 |
| Death domain (`Raw_Death`, a death date recorded) | 12 |
| Discontinuation reason `"Death"` (`Raw_STUDCOMP`) | 1 (`S34463`) |
| Named by both sources | 0 |
| **Union, all participants** | **13** |
| **Union, enrolled participants only** | **12** |
| In the union but never enrolled | 1 (`S39113`) |

The published row, from both routes:

| GroupID | GroupLevel | Numerator | Denominator | Metric | Score | Flag |
|---|---|---|---|---|---|---|
| AA-AA-000-0000 | Study | 12 | 760 | 0.0157894… | 12 | *(empty)* |

The two routes agree. The flag is empty rather than zero — this metric does not
flag.

## The finding: thirteen, then twelve

D0023 published **thirteen** as the count this metric would report, and thirteen
is right for the figure it names — `gsm.mapping`'s union of the two death
sources, which route A reproduces exactly. It is not the figure the metric
publishes.

One of the thirteen, **`S39113`**, has a death record (`death_dt`
2012-03-13) but `enrollyn = "N"`, no enrolment date and no time on study. The
standard mapping's `Mapped_SUBJ` is `WHERE enrollyn == 'Y'`, so that
participant is not in the enrolled population, and the same design's other rule
excludes them:

> Every one of them uses the standard rate step, which anchors the count to the
> enrolled participants and looks the rest up against them. […] a participant
> identifier that appears in a disposition record but was never enrolled cannot
> be counted, and the count and the denominator can no longer disagree.

The two statements cannot both hold on this study. The anchor wins, for the
reason the anchor exists: publishing 13 over a denominator of 760 would put a
person in the numerator who is not in the denominator — the same defect shape
the review found when it caught five completers in a four-person study. So the
metric reports **12 of 760**, and the number D0023 published, 13, is the
unanchored union recorded above it.

Both figures are kept in the table on purpose. Neither is wrong; they answer
different questions, and the difference is one identifiable participant.

The correction that matters is unchanged either way: `SafetyCensus()` reports
**one** death on this study today, by text-matching a discontinuation reason.

## Absent, empty, zero

The three states the count must never collapse, checked in
`tests/testthat/test-Input_Deaths.R` and `test-workflow-death-metric.R`:

| State | The study said | The metric does |
|---|---|---|
| Absent | no death domain, or no `death` / `subjid` column in it | errors |
| Empty | a death domain with no rows | publishes no row, and warns |
| Zero | a populated death domain marking nobody as died | publishes `0` |

One thing worth naming, because the design assumed otherwise:
`gsm.core::CheckSpec()` (1.2.0) **errors on a missing data.frame but only warns
on a missing declared column**. Declaring the columns in `saf0004.yaml` is
therefore necessary but not sufficient — `Input_Deaths()` checks its own columns
and stops, which is what makes the absent state an error rather than a zero.
