<!--
NEWS.md is the running release log and the draft of each release's notes
(obot.agent/skills/rc-release-notes/SKILL.md): newest section first; unreleased
work accumulates under a vX.Y.Z (Upcoming) heading that loses the suffix when
the release is cut; the GitHub release publishes from the section verbatim.
-->

# gsm.safety v1.3.0 (Upcoming)

The first of the thirteen census metrics: the death count. Step one of four in the SafetyCensus rebuild ([obot.roadmap#274](https://github.com/jwildfire/obot.roadmap/issues/274), design [D0023](https://jwildfire.github.io/obot.roadmap/reports/decisions/2026-08-20-safety-census-rebuild/) approved 2026-08-20). It is first because it is the number the review was written about.

## The figure that moves, and why it was wrong

`SafetyCensus()` reports one death on the ecosystem's bundled study. It reaches that number by matching the text of a discontinuation reason in the study-completion domain, which on that study names four participants of whom one is enrolled. It never reads the study's death domain at all, and that domain names twelve more.

The new `saf0004` metric reports 13 deaths of 762 enrolled participants on the same study — a thirteenfold correction to a published clinical figure, and the entire reason this rebuild exists.

Three numbers, kept apart, because they answer different questions:

- **16** — the two death sources combined: 12 participants with a death record, plus 4 whose discontinuation reason is `Death`, with no overlap between them. This is `gsm.mapping`'s union, and it is correct for what it names.
- **13** — what the metric publishes. Three of the sixteen have `enrollyn = "N"`: never enrolled, no enrolment date, no time on study. Every gsm metric anchors its count to the enrolled population, so publishing 16 over a denominator of 762 would put three people in the numerator who are not in the denominator — the defect shape the review caught elsewhere as five completers in a four-person study. The anchor wins; the difference is three identifiable participants, named in `design/death-count-qualification.md` rather than absorbed.
- **1** — what `SafetyCensus()` still returns, and will keep returning until step four rewrites it. This release adds the metric beside the function; it does not change the function, so no figure on the demo study's safety page moves yet. The gap between 1 and 13 is now measured, recorded and reproducible instead of unknown.

The count is qualified rather than asserted: it is measured twice on the same study by two routes that share no code — the death records read directly with base R, and the standard mapping run through the workflow — and both land on 13. The evidence, the versions and the reproducer are recorded in `design/death-count-qualification.md` and run in the suite as `tests/testthat/test-qualification-death-count.R`.

## What's new

- **`saf0004`, a descriptive study-level death count** ([#56](https://github.com/jwildfire/gsm.safety/issues/56)) — counted from `Mapped_Death`, which is `gsm.mapping`'s own union of the death domain and the discontinuation reason, so no clinical definition of death is written in this package. The metric declares every column it reads, counts each participant once however many rows the domain carries for them, and anchors the count to the enrolled population.
- **The metric does not flag, and cannot** ([#56](https://github.com/jwildfire/gsm.safety/issues/56)) — no threshold in its meta, no flagging step in its workflow, nothing amber and nothing red (D0023.3). New exported step `Flag_None()` stands where `gsm.core::Flag()` would and leaves the flag empty, following gsm.kri's `srs0001` site risk score, which has published its rows that way in production throughout. Empty, not zero: a zero would mean measured and found fine. Because the metric carries no threshold it contributes no weights, so gsm.kri's risk-score builder skips it and this figure cannot move a site's risk score.
- **New exported step `Input_Deaths()`** ([#56](https://github.com/jwildfire/gsm.safety/issues/56)) — the numerator behind `saf0004`, and where the three states are kept apart: a study with no death domain, or a death domain missing a declared column, errors; a death domain with no rows at all publishes no figure and warns; a populated death domain marking nobody as died publishes zero. Absent is not empty and empty is not zero — only the last of the three is a measurement.
- **Study level is a setting, not a rewrite** ([#56](https://github.com/jwildfire/gsm.safety/issues/56)) — `GroupLevel` and `GroupCol` are meta values the workflow reads, so moving the metric to site or country level is two lines rather than a second definition (D0023.4).

## Worth knowing

- **The bundled study moves, so the qualification is version-pinned.** Between gsm.core 1.2.0 and 1.3.1 the reference study changed under the same name: enrolled went from 760 to 762 and discontinuation-reason deaths from 1 to 4, taking the published count from 12 to 13. The qualification test always checks the identities that hold on any version — that the two routes agree, that the count is the union anchored to the enrolled population, that it exceeds the 1 the function reports — and pins the exact counts to the gsm.core version they were measured on. A different version skips those two assertions with the recorded and the live numbers both named. Re-qualifying a clinical count is a deliberate act, not a silent re-derivation.
- **`gsm.core::CheckSpec()` only warns on a missing column.** The design assumed a declared column that is missing would stop the workflow with an error. It errors on a missing *data.frame* but merely warns on a missing *column*. Declaring the columns is therefore necessary but not sufficient, and `Input_Deaths()` checks its own columns and stops. The remaining twelve metrics need the same guard.
- **Nothing upstream changed and nothing downstream moved.** `SafetyCensus()` resolves and returns exactly what it returned before, the three existing `saf000*` metrics are untouched, and the new row lands beside the flagging ones through the ordinary `Analyze` → `Summarize` chain.

# gsm.safety v1.2.0 (Upcoming)

- **Two new widgets — `Widget_HepWaterfall()` and `Widget_NepExplorer()`** — the hepatic ALT waterfall for abnormal-baseline trials (Amirzadegan et al. 2025, Fig. 5) and the KDIGO nephrotoxicity explorer, each with its report workflow, example page, and bundled demo cohort (`adbds_abnbl`; synthetic `AKI-*` participants join `adbds`). ([obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164), [#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **The vendored safety.viz bundle moves from v1.4.0 to v1.7.0**, so every widget renders with three releases of upstream fixes and features it was missing. One of them changes clinical numbers: the corrected eDISH peak computation ([safety.viz#91](https://github.com/jwildfire/safety.viz/issues/91)) — the v1.4.0 bundle excluded a participant's baseline record from their on-treatment peaks *by study day* rather than *by identity*, so a participant with no day-0 record had their own baseline counted as an on-treatment peak and could never show a below-baseline peak. Measured on the bundled `adbds` example data, 24 of 364 participants have no day-0 hepatic record and hit the corrected rule: the composite eDISH view now plots 293 participants with 71 excluded (was 295 / 69), 9 participants' plotted peak values move, and 2 leave the plot because they have no genuine on-treatment peak. Quadrant classification is unchanged on this data. The corrected reduction feeds `Widget_HepExplorer()`'s composite and migration views and `Widget_HepWaterfall()`. Everything else the catch-up brings is feature or appearance: participant-profile drill-down on six charts, the migration Sankey view, eDISH direct manipulation and study-day playback, the shared hep/qt view selector, log-base and axis-limit controls. ([#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **A safety.viz parity guard makes the next drift loud**: `DESCRIPTION` declares the wrapped library version (`Config/safetyviz/version`), an offline test keeps the declaration, the vendored bundle, and every widget binding in agreement, and a CI workflow checks the latest safety.viz release — blocking PRs on unwrapped renderers unless `.github/parity-allowlist.yaml` cites a filed requirement, and filing an adoption issue automatically on its weekly schedule. ([obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164), [#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **Two of safety.viz's thirteen renderers stay unwrapped, on the record**: `participantProfile` and `timeToEvent` are cited deferrals in `.github/parity-allowlist.yaml`, each pointing at [obot.roadmap#165](https://github.com/jwildfire/obot.roadmap/issues/165). Both need two data frames, which the single-`dfResults` widget contract cannot carry, so they are a design question rather than a mechanical wrap. The parity check fails on a deferral that cites nothing, so this cannot quietly become "we forgot". ([#49](https://github.com/jwildfire/gsm.safety/issues/49))

# gsm.safety v1.1.0

**See it move:** the [annotated v1.1 demo](https://jwildfire.github.io/obot.roadmap/reports/gs-v1.1-demo/) walks the new metrics running live on the [DEMO-301 study site](https://jwildfire.github.io/demo-301/#/safety), with captures and try-it-yourself steps.

gsm.safety could draw the eDISH chart but could not tell you how many participants were in the Hy's Law quadrant. This release adds the metrics phase that answers that — three participant-level safety metrics plus the denominators a safety overview leads with — and moves the report workflows into the standard gsm phase layout on the way. One path changes: workflows formerly under `inst/workflow/3_reports/` now live in `inst/workflow/4_modules/`.

## What's new

- **A `2_metrics` workflow phase: three participant-level safety metrics** ([#45](https://github.com/jwildfire/gsm.safety/issues/45), PR [#47](https://github.com/jwildfire/gsm.safety/pull/47); hub [obot.roadmap#138](https://github.com/jwildfire/obot.roadmap/issues/138)). `saf0001` Hy's Law candidate, `saf0002` QTcF prolongation, and `saf0003` serious / related AE — each scores one row per participant with an ordinal tier through the standard gsm contract (`Analyze_Identity()` + `Flag()`, following gsm.kri's `pat0015` precedent), so subject-level rows land in `Reporting_Results` beside site and country rows with nothing downstream changing. The liver and QT cut-points come from the vendored data contracts of the charts they correspond to, so the metric and the chart cannot drift apart. Measured on demo data before being treated as real (the hub#138 gate): 9 / 11 / 68 red-tier participants of 765 scored. [See them live](https://jwildfire.github.io/demo-301/#/safety/metric/saf0001).
- **`SafetyCensus()`** (PR [#47](https://github.com/jwildfire/gsm.safety/pull/47)) — reduces the mapped domains to the denominators a safety overview leads with: enrollment, exposure, person-years, deaths, and **data coverage per visit** — the figure that decides whether a quiet visit is reassuring or empty. New exported helpers behind the metrics: `Input_HysLaw()`, `Input_QtProlongation()`, `Input_SafetyAE()`.
- **Report workflows move to `inst/workflow/4_modules/`** ([#46](https://github.com/jwildfire/gsm.safety/issues/46), PR [#47](https://github.com/jwildfire/gsm.safety/pull/47); hub [obot.roadmap#136](https://github.com/jwildfire/obot.roadmap/issues/136)) — the standard gsm phase directory for `meta.Type: Report` workflows, the one gsm.kri already uses. Update any pipeline that globbed `3_reports/`.

1 286 tests pass; `R CMD check` clean.

# Earlier releases

- [v1.0.0](https://github.com/jwildfire/gsm.safety/releases/tag/v1.0.0) — 2026-07-23.
- [gsm.safety v0.1.0](https://github.com/jwildfire/gsm.safety/releases/tag/v0.1.0) — 2026-05-15.
