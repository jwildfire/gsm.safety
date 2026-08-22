# Qualifying the census report (`safety_census`)

Recorded 2026-08-21 · [gsm.safety#61](https://github.com/jwildfire/gsm.safety/issues/61) ·
[obot.roadmap#274](https://github.com/jwildfire/obot.roadmap/issues/274) ·
[D0023](https://jwildfire.github.io/obot.roadmap/reports/decisions/2026-08-20-safety-census-rebuild/)

Installed with the package: `inst/qualification/census-report-qualification.md`
in the repository, and
`system.file("qualification", "census-report-qualification.md",
package = "gsm.safety")` once installed
([#63](https://github.com/jwildfire/gsm.safety/issues/63)). The record travels
with the thing it qualifies, and every figure below is compared with the code
by the test suite in every context it runs in — `R CMD check` included.

The report computes nothing, so qualifying it is not a matter of re-deriving
its figures — it is a matter of showing that the numbers a reader sees on the
page are the numbers already qualified in
[`census-metrics-qualification.md`](census-metrics-qualification.md) and
[`death-count-qualification.md`](death-count-qualification.md), presented
without arithmetic except the one division the report is told to do.

## What was measured

Bundled study `AA-AA-000-0000`, from `gsm.core::lSource`.
`gsm.core` 1.3.1, `gsm.mapping` 1.1.6, `gsm.reporting` 1.1.5, R 4.3.3.

The whole pipeline was run — the standard mapping, the eleven census metrics
that have a domain on this study, `gsm.reporting::BindResults()` and
`MakeMetric()` into `Reporting_Results` and `Reporting_Metrics`, then the
`safety_census` workflow — and the rendered page read back.

| Metric | On the page | Qualified figure | Published by the metric |
|---|---|---|---|
| `saf0005` | 762 of 762 | 762 | 762 |
| `saf0006` | 577 of 762 | 577 | 577 |
| `saf0007` | 762 of 762 | 762 | 762 |
| `saf0004` | 13 of 762 | 13 | 13 |
| `saf0008` | 73.2 person-years of 762 | 26,754 days | 26,754 |
| `saf0009` | 29.5 person-years of 762 | 10,761 days | 10,761 |
| `saf0010` | 598 of 762 | 598 | 598 |
| `saf0011` | *no row published* | *no domain* | *nothing* |
| `saf0012` | 661 of 762 | 661 | 661 |
| `saf0013` | 76 of 762 | 76 | 76 |
| `saf0014` | 19 of 762 | 19 | 19 |
| `saf0015` | 9 of 762 | 9 | 9 |

Every figure on the page is the numerator its metric published, beside the
denominator that same metric published. The two exposure rows are the only
figures the report transforms, and both numbers reach the reader: the years in
the exposure table, the days in the provenance table below it.

The page carries no coverage section, because no coverage metric exists to read
(see [#58](https://github.com/jwildfire/gsm.safety/issues/58)).

## The three checks, and why three

`tests/testthat/test-qualification-census-report.R` runs all of them.

1. **The page against the record.** The pipeline above runs in the suite and
   every presented figure is compared with the recorded one. Pinned to the
   gsm.core version the figures were measured on; a different version skips
   with both versions named.
2. **The record against the design files.** The constants in the test are
   compared against the qualification tables in
   `census-metrics-qualification.md` and `death-count-qualification.md`, parsed
   out of the markdown. A figure re-measured in one of those files and not in
   the test now fails rather than becoming a quiet disagreement between two
   documents.
3. **The reading property itself**, in
   `tests/testthat/test-census-report.R`: the report is handed results that are
   deliberately *not* any real study's, and has to present them. A helper that
   recounted anything would be caught by its own correctness. None of the four
   report steps takes a study domain as an argument, which is asserted too.

## The finding: the reference study has moved again

`gsm.core`'s `main` branch — which this package's `Remotes` track, and which CI
installs — is at **1.3.1.9000**, and its bundled `AA-AA-000-0000` is a
different study from 1.3.1's. Measured with the same twelve metrics:

| Metric | 1.3.1 (recorded) | 1.3.1.9000 (`main` today) |
|---|---|---|
| Enrolled | 762 | 758 |
| Randomised | 577 | 590 |
| Dosed | 762 | 682 |
| Deaths | 13 | 12 |
| Participant-days on study | 26,754 | 26,461 |
| Participant-days on treatment | 10,761 | 10,468 |
| With a lab result | 598 | 558 |
| With a reported AE | 661 | 660 |
| With a disposition record | 76 | 76 |
| Completed | 19 | 18 |
| Discontinued | 9 | 5 |

Nothing here says a metric is wrong: all twelve compute correctly on both
studies. What it says is that the recorded snapshot in these three files
describes a study that gsm.core's `main` no longer ships, and that both
qualification suites therefore **skip** their snapshot assertions on `main`
today rather than failing on them. That is the pinning convention working as
designed — a clinical figure whose reference study moved is re-checked by a
person, not silently re-derived — but it means the snapshot is not being
exercised in CI, and re-qualification is now outstanding work rather than a
hypothetical.

One consequence is worth having when it happens: on the newer study a recorded
first dose is no longer the same thing as enrolment (682 against 758), so
`saf0007` and `saf0005` can finally be told apart on the reference study —
which `census-metrics-qualification.md` records as something the 1.3.1 study
could not do.

## Two figures D0023 put in the report that are not in it

The design places two things in the report that the metric layer cannot
express: the median days on treatment, computed from the exposure metric's
per-participant table, and the breakdown of discontinuation reasons, built from
free text.

[#61](https://github.com/jwildfire/gsm.safety/issues/61) sets a harder bar than
the design did — *if a number is needed and no metric produces it, that is a
missing metric, not a calculation to put here* — and the bar was followed. A
median computed in the report is a second counting lane whatever table it is
computed from, and a reason breakdown assembled from a raw domain is the report
reading study data rather than metric results.

Both are named rather than dropped: the median wants an averaging step in the
metric layer, and the reason breakdown wants an enumeration that layer has no
way to declare in advance. The blank-reason defect D0023's table marks as
"fixed in the report's disposition helper" is therefore **not** fixed by this
step; it is still inside `SafetyCensus()`, which step four rewrites.
