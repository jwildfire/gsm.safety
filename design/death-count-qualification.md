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

The script exits non-zero if the two routes disagree. The same two routes run in
the suite as `tests/testthat/test-qualification-death-count.R`.

## What was measured

Bundled study `AA-AA-000-0000`, from `gsm.core::lSource`.
`gsm.core` 1.3.1, `gsm.mapping` 1.1.6, R 4.3.

| Figure | Count |
|---|---|
| Participants in `Raw_SUBJ` | 1000 |
| Enrolled (`enrollyn == "Y"`) — the denominator | 762 |
| Death domain (`Raw_Death`, a death date recorded) | 12 |
| Discontinuation reason `"Death"` (`Raw_STUDCOMP`) | 4 |
| Named by both sources | 0 |
| Union, all participants | 16 |
| **Union, enrolled participants only** | **13** |
| In the union but never enrolled | 3 (`S42425`, `S97688`, `S78705`) |

The published row, from both routes:

| GroupID | GroupLevel | Numerator | Denominator | Metric | Score | Flag |
|---|---|---|---|---|---|---|
| AA-AA-000-0000 | Study | 13 | 762 | 0.0170603… | 13 | *(empty)* |

The two routes agree on 13. The flag is empty rather than zero — this metric
does not flag.

> **Corrected 2026-08-21**, while qualifying the remaining twelve metrics
> ([#58](https://github.com/jwildfire/gsm.safety/issues/58)). This line said
> `SafetyCensus()` reports **1** on the same study. Measured on `gsm.core`
> 1.3.1 with the standard mapped domains it reports **4**: one is what it
> reported on 1.2.0, and the function does not anchor its death count to the
> enrolled population, so it counts all four participants whose discontinuation
> reason says `Death` — three of them enrolled, one not. The correction this
> metric makes is 4 → 13. The count of 13 below was re-measured on 1.3.1 and is
> unchanged. See `design/census-metrics-qualification.md`.

## The finding: sixteen, then thirteen

D0023 published thirteen as the count, arrived at as twelve death records plus
one discontinuation reason. Thirteen is what the metric publishes, but not by
that arithmetic, and the difference is worth recording because it is the rule
that makes the number trustworthy rather than a coincidence.

On this study the two sources name **sixteen** distinct participants — 12 from
the death domain, 4 from the discontinuation reason, with no overlap. Three of
the sixteen have `enrollyn = "N"`: never enrolled, no enrolment date, no time on
study — two of them from the death domain (`S42425`, `S97688`) and one from the
discontinuation reason (`S78705`), re-measured 2026-08-21. The standard mapping's `Mapped_SUBJ` is `WHERE enrollyn == 'Y'`, so they
are not in the enrolled population, and the design's own rule excludes them:

> Every one of them uses the standard rate step, which anchors the count to the
> enrolled participants and looks the rest up against them. […] a participant
> identifier that appears in a disposition record but was never enrolled cannot
> be counted, and the count and the denominator can no longer disagree.

Publishing 16 over a denominator of 762 would put three people in the numerator
who are not in the denominator — the defect shape the review caught elsewhere
as five completers in a four-person study. So the anchor applies and the metric
reports 13 of 762.

Both figures are kept above on purpose. Neither is wrong; they answer different
questions, and the difference is three identifiable participants.

## The snapshot is version-pinned, on purpose

The bundled study is not fixed. gsm.safety tracks `gsm.core`'s `main` branch,
and between **gsm.core 1.2.0 and 1.3.1** that study changed under the same
name:

| Figure | gsm.core 1.2.0 | gsm.core 1.3.1 |
|---|---|---|
| Enrolled | 760 | 762 |
| Death domain | 12 | 12 |
| Discontinuation reason `"Death"` | 1 | 4 |
| Union, all | 13 | 16 |
| Union, enrolled — the published count | 12 | 13 |

So the qualification test asserts two different kinds of thing. The identities
between the two routes — that they land on the same number, that the number is
the union anchored to the enrolled population, that it exceeds the 1 the
function reports today — hold on any version and are always checked. The exact
counts above are a snapshot, asserted only against the `gsm.core` version they
were measured on; a different version skips those two tests with the recorded
numbers and the live numbers both named in the skip reason, and a pointer to
this file.

Re-qualifying is therefore a deliberate act: run the reproducer, update this
file and the `RECORDED` list in the test. A clinical count whose reference
study moved should be re-checked by a person, not silently re-derived.

## Absent, empty, zero

The three states the count must never collapse, checked in
`tests/testthat/test-Input_Deaths.R` and `test-workflow-death-metric.R`:

| State | The study said | The metric does |
|---|---|---|
| Absent | no death domain, or no `death` / `subjid` column in it | errors |
| Empty | a death domain with no rows | publishes no row, and warns |
| Zero | a populated death domain marking nobody as died | publishes `0` |

One thing worth naming, because the design assumed otherwise:
`gsm.core::CheckSpec()` **errors on a missing data.frame but only warns on a
missing declared column**. Declaring the columns in `saf0004.yaml` is therefore
necessary but not sufficient — `Input_Deaths()` checks its own columns and
stops, which is what makes the absent state an error rather than a zero.
