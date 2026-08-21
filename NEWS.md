<!--
NEWS.md is the running release log and the draft of each release's notes
(obot.agent/skills/rc-release-notes/SKILL.md): newest section first; unreleased
work accumulates under a vX.Y.Z (Upcoming) heading that loses the suffix when
the release is cut; the GitHub release publishes from the section verbatim.
-->

# gsm.safety v1.2.0 (Upcoming)

- **Two new widgets — `Widget_HepWaterfall()` and `Widget_NepExplorer()`** — the hepatic ALT waterfall for abnormal-baseline trials (Amirzadegan et al. 2025, Fig. 5) and the KDIGO nephrotoxicity explorer, each with its report workflow, example page, and bundled demo cohort (`adbds_abnbl`; synthetic `AKI-*` participants join `adbds`). ([obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164), [#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **The vendored safety.viz bundle moves from v1.4.0 to v1.6.0**, so every widget now renders with two releases of upstream fixes and features it was missing — including the corrected eDISH peak computation ([safety.viz#91](https://github.com/jwildfire/safety.viz/issues/91): the v1.4.0 bundle counted a participant's own baseline as an on-treatment peak when no day-0 record existed), participant-profile drill-down on six charts, the migration Sankey view, eDISH direct manipulation, study-day playback, and the shared hep/qt view selector. ([#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **A safety.viz parity guard makes the next drift loud**: `DESCRIPTION` declares the wrapped library version (`Config/safetyviz/version`), an offline test keeps the declaration, the vendored bundle, and every widget binding in agreement, and a CI workflow checks the latest safety.viz release — blocking PRs on unwrapped renderers unless `.github/parity-allowlist.yaml` cites a filed requirement, and filing an adoption issue automatically on its weekly schedule. ([obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164), [#49](https://github.com/jwildfire/gsm.safety/issues/49))

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
