# Changelog

## gsm.safety v1.2.0 (Upcoming)

**See it move:** the [annotated v1.2.0
demo](https://jwildfire.github.io/obot.roadmap/reports/gsm-safety-v1.2.0-demo/)
has captures, try-it steps and the detail behind everything below.

gsm.safety v1.2.0 brings the widgets up to safety.viz v1.12.0 and
rebuilds the safety census on qualified metrics. Two published clinical
figures change: the liver composite view no longer reads a baseline as a
peak, and the bundled study’s death count goes from 2 to 12.
[`SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/SafetyCensus.md)
keeps its name and arguments; its figures are qualified on gsm.core
1.3.2.

### What’s new

- **The death count reads both death sources and counts only enrolled
  participants.** It counts the death domain and a discontinuation
  reason of death, in any case. On the bundled study it reports 12 of
  754 where
  [`SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/SafetyCensus.md)
  reported 2.
  [obot.roadmap#274](https://github.com/jwildfire/obot.roadmap/issues/274),
  [\#56](https://github.com/jwildfire/gsm.safety/issues/56), PR
  [\#57](https://github.com/jwildfire/gsm.safety/pull/57),
  [\#168](https://github.com/jwildfire/gsm.safety/issues/168), PR
  [\#169](https://github.com/jwildfire/gsm.safety/pull/169)
- **The safety census is twelve metrics, each published beside its own
  denominator.** Four more figures move on the bundled study: randomised
  567 (was blank), received study drug 679 (was 599), disposition 94
  (was 116), and the ECG figure reads absent, not blank.
  [obot.roadmap#274](https://github.com/jwildfire/obot.roadmap/issues/274),
  [\#61](https://github.com/jwildfire/gsm.safety/issues/61), PR
  [\#62](https://github.com/jwildfire/gsm.safety/pull/62),
  [\#66](https://github.com/jwildfire/gsm.safety/issues/66), PR
  [\#67](https://github.com/jwildfire/gsm.safety/pull/67)
- **The hep-explorer’s composite view no longer counts a baseline as an
  on-treatment peak.** The bundle moves from safety.viz v1.4.0 to
  v1.12.0; on the example data 23 synthetic participants’ peaks fall,
  and Hy’s Law drops from 28 to 13.
  [obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164),
  [safety.viz#91](https://github.com/jwildfire/safety.viz/issues/91),
  [\#49](https://github.com/jwildfire/gsm.safety/issues/49), PR
  [\#51](https://github.com/jwildfire/gsm.safety/pull/51),
  [obot.roadmap#438](https://github.com/jwildfire/obot.roadmap/issues/438),
  [\#165](https://github.com/jwildfire/gsm.safety/issues/165), PR
  [\#169](https://github.com/jwildfire/gsm.safety/pull/169)
- **Every chart safety.viz draws can be drawn from R.** Four widgets are
  new, making thirteen:
  [`Widget_HepWaterfall()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_HepWaterfall.md),
  [`Widget_NepExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_NepExplorer.md),
  [`Widget_TimeToEvent()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_TimeToEvent.md)
  and
  [`Widget_ParticipantProfile()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ParticipantProfile.md).
  [obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164),
  [obot.roadmap#165](https://github.com/jwildfire/obot.roadmap/issues/165),
  [\#49](https://github.com/jwildfire/gsm.safety/issues/49), PR
  [\#51](https://github.com/jwildfire/gsm.safety/pull/51),
  [\#71](https://github.com/jwildfire/gsm.safety/issues/71), PR
  [\#72](https://github.com/jwildfire/gsm.safety/pull/72)
- **Four widgets take the Visit \| Study day toggle.** The participant
  profile, hep-explorer, outlier explorer and QT explorer accept
  `x_axis` in `lSettings`; the hep waterfall reads `DY` as its study
  day. The example data now carries `DY` and `ABLFL`.
  [obot.roadmap#438](https://github.com/jwildfire/obot.roadmap/issues/438),
  [\#165](https://github.com/jwildfire/gsm.safety/issues/165), PR
  [\#169](https://github.com/jwildfire/gsm.safety/pull/169),
  [\#166](https://github.com/jwildfire/gsm.safety/issues/166), PR
  [\#167](https://github.com/jwildfire/gsm.safety/pull/167)
- **The FDA safety guide’s appendix tables, and three of its rules, are
  in R.** `FDA_AbnormalityLevels` and `FDA_ExtremeValues` are package
  data, and
  [`Derive_ULNMultiple()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ULNMultiple.md),
  [`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md)
  and
  [`Derive_ExtremeValueFlag()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ExtremeValueFlag.md)
  apply them.
  [obot.roadmap#9](https://github.com/jwildfire/obot.roadmap/issues/9),
  [\#77](https://github.com/jwildfire/gsm.safety/issues/77), PR
  [\#83](https://github.com/jwildfire/gsm.safety/pull/83),
  [\#78](https://github.com/jwildfire/gsm.safety/issues/78), PR
  [\#86](https://github.com/jwildfire/gsm.safety/pull/86),
  [\#79](https://github.com/jwildfire/gsm.safety/issues/79), PR
  [\#84](https://github.com/jwildfire/gsm.safety/pull/84),
  [\#80](https://github.com/jwildfire/gsm.safety/issues/80), PR
  [\#85](https://github.com/jwildfire/gsm.safety/pull/85)

### Deprecated

- **[`SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/SafetyCensus.md)’s
  column arguments are deprecated and ignored; no release removing them
  is set yet.** `strArmCol`, `strReasonCol`, `chrDeathValues` and the
  rest still run, warn, and change no figure, because each metric
  declares the columns it reads. Pass the mapped domains instead,
  including the new `dfDeath` and `dfRandomization`.
  [\#66](https://github.com/jwildfire/gsm.safety/issues/66), PR
  [\#67](https://github.com/jwildfire/gsm.safety/pull/67)

### Removed

- **The histogram’s `test_normality` and `compare_distributions`
  settings.** safety.viz no longer draws p-values on the histogram, so
  drop them from your calls.
  [\#158](https://github.com/jwildfire/gsm.safety/issues/158), PR
  [\#163](https://github.com/jwildfire/gsm.safety/pull/163)

### Also in this release

- **The QT explorer averages replicate readings, so its `n` counts
  participants.**
  [\#158](https://github.com/jwildfire/gsm.safety/issues/158), PR
  [\#163](https://github.com/jwildfire/gsm.safety/pull/163)
- **[`BuildWidgetPayload()`](https://jwildfire.github.io/gsm.safety/dev/reference/BuildWidgetPayload.md)
  refuses a setting it cannot send, naming it:** a missing
  limit-of-normal column, a value that is not one string, `NULL`, a
  group that is not a list, or too few rows.
  [\#99](https://github.com/jwildfire/gsm.safety/issues/99), PR
  [\#101](https://github.com/jwildfire/gsm.safety/pull/101),
  [\#103](https://github.com/jwildfire/gsm.safety/issues/103), PR
  [\#104](https://github.com/jwildfire/gsm.safety/pull/104),
  [\#109](https://github.com/jwildfire/gsm.safety/issues/109), PR
  [\#113](https://github.com/jwildfire/gsm.safety/pull/113),
  [\#125](https://github.com/jwildfire/gsm.safety/issues/125), PR
  [\#130](https://github.com/jwildfire/gsm.safety/pull/130),
  [\#149](https://github.com/jwildfire/gsm.safety/issues/149), PR
  [\#150](https://github.com/jwildfire/gsm.safety/pull/150)
- **The participant profile refuses malformed adverse-event settings,
  and examples drop placeholder rows.**
  [\#107](https://github.com/jwildfire/gsm.safety/issues/107), PR
  [\#112](https://github.com/jwildfire/gsm.safety/pull/112),
  [\#119](https://github.com/jwildfire/gsm.safety/issues/119), PR
  [\#122](https://github.com/jwildfire/gsm.safety/pull/122), PR
  [\#124](https://github.com/jwildfire/gsm.safety/pull/124),
  [\#139](https://github.com/jwildfire/gsm.safety/issues/139), PR
  [\#140](https://github.com/jwildfire/gsm.safety/pull/140)
- **[`SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/SafetyCensus.md)
  names bad input instead of counting it:** an infinite day count, a
  domain without the ID column, a group column the subjects lack or that
  collides with the ID, and settings given as a data.frame.
  [\#96](https://github.com/jwildfire/gsm.safety/issues/96), PR
  [\#97](https://github.com/jwildfire/gsm.safety/pull/97),
  [\#117](https://github.com/jwildfire/gsm.safety/issues/117), PR
  [\#118](https://github.com/jwildfire/gsm.safety/pull/118),
  [\#126](https://github.com/jwildfire/gsm.safety/issues/126), PR
  [\#131](https://github.com/jwildfire/gsm.safety/pull/131),
  [\#144](https://github.com/jwildfire/gsm.safety/issues/144), PR
  [\#146](https://github.com/jwildfire/gsm.safety/pull/146),
  [\#133](https://github.com/jwildfire/gsm.safety/issues/133), PR
  [\#134](https://github.com/jwildfire/gsm.safety/pull/134)
- **The report writers refuse an output file or directory that is
  missing, empty or not one string.**
  [\#106](https://github.com/jwildfire/gsm.safety/issues/106), PR
  [\#111](https://github.com/jwildfire/gsm.safety/pull/111),
  [\#115](https://github.com/jwildfire/gsm.safety/issues/115), PR
  [\#116](https://github.com/jwildfire/gsm.safety/pull/116),
  [\#143](https://github.com/jwildfire/gsm.safety/issues/143), PR
  [\#145](https://github.com/jwildfire/gsm.safety/pull/145),
  [\#120](https://github.com/jwildfire/gsm.safety/issues/120), PR
  [\#123](https://github.com/jwildfire/gsm.safety/pull/123),
  [\#135](https://github.com/jwildfire/gsm.safety/issues/135), PR
  [\#136](https://github.com/jwildfire/gsm.safety/pull/136)
- **The derivations refuse to overwrite an input column, and a frame
  already carrying `AbnormalityDirection` is refused too.** The
  requirement matrix now describes grading as shipped.
  [\#102](https://github.com/jwildfire/gsm.safety/issues/102), PR
  [\#105](https://github.com/jwildfire/gsm.safety/pull/105),
  [\#128](https://github.com/jwildfire/gsm.safety/issues/128), PR
  [\#132](https://github.com/jwildfire/gsm.safety/pull/132)
- **The qualification records ship inside the package, and the suite
  checks their figures against the code.**
  [\#63](https://github.com/jwildfire/gsm.safety/issues/63), PR
  [\#64](https://github.com/jwildfire/gsm.safety/pull/64),
  [\#153](https://github.com/jwildfire/gsm.safety/issues/153), PR
  [\#154](https://github.com/jwildfire/gsm.safety/pull/154)
- **Dependencies install from Gilead-Public, and four workflows that
  failed before starting run again.**
  [\#160](https://github.com/jwildfire/gsm.safety/issues/160), PR
  [\#161](https://github.com/jwildfire/gsm.safety/pull/161),
  [\#55](https://github.com/jwildfire/gsm.safety/issues/55), PR
  [\#73](https://github.com/jwildfire/gsm.safety/pull/73)
- **The package site wears the hub’s theme, and the repository carries
  the CLAUDE.md its guidelines ask for.** PR
  [\#94](https://github.com/jwildfire/gsm.safety/pull/94), PR
  [\#95](https://github.com/jwildfire/gsm.safety/pull/95),
  [\#81](https://github.com/jwildfire/gsm.safety/issues/81), PR
  [\#82](https://github.com/jwildfire/gsm.safety/pull/82)
- **Four things are knowingly not in this release:** data completeness
  in the census, an ECG figure (gsm.mapping maps no ECG domain), the
  Patient Journey Explorer widget, and a ruling on three charts that
  ship computing statistics in JavaScript.
  [\#58](https://github.com/jwildfire/gsm.safety/issues/58),
  [\#172](https://github.com/jwildfire/gsm.safety/issues/172),
  [obot.roadmap#350](https://github.com/jwildfire/obot.roadmap/issues/350),
  [safety.viz#259](https://github.com/jwildfire/safety.viz/issues/259)

### Tests and provenance

4,654 tests pass against gsm.core 1.3.2, gsm.mapping 1.2.0 and
gsm.reporting 1.1.8. Every census figure is measured twice, by two
routes that share no code. The vendored bundle is byte-identical to
safety.viz v1.12.0 (`122ec3f`), which the parity check confirms.

## gsm.safety v1.1.0

**See it move:** the [annotated v1.1
demo](https://jwildfire.github.io/obot.roadmap/reports/gs-v1.1-demo/)
walks the new metrics running live on the [DEMO-301 study
site](https://jwildfire.github.io/demo-301/#/safety), with captures and
try-it-yourself steps.

gsm.safety could draw the eDISH chart but could not tell you how many
participants were in the Hy’s Law quadrant. This release adds the
metrics phase that answers that — three participant-level safety metrics
plus the denominators a safety overview leads with — and moves the
report workflows into the standard gsm phase layout on the way. One path
changes: workflows formerly under `inst/workflow/3_reports/` now live in
`inst/workflow/4_modules/`.

### What’s new

- **A `2_metrics` workflow phase: three participant-level safety
  metrics** ([\#45](https://github.com/jwildfire/gsm.safety/issues/45),
  PR [\#47](https://github.com/jwildfire/gsm.safety/pull/47); hub
  [obot.roadmap#138](https://github.com/jwildfire/obot.roadmap/issues/138)).
  `saf0001` Hy’s Law candidate, `saf0002` QTcF prolongation, and
  `saf0003` serious / related AE — each scores one row per participant
  with an ordinal tier through the standard gsm contract
  (`Analyze_Identity()` + `Flag()`, following gsm.kri’s `pat0015`
  precedent), so subject-level rows land in `Reporting_Results` beside
  site and country rows with nothing downstream changing. The liver and
  QT cut-points come from the vendored data contracts of the charts they
  correspond to, so the metric and the chart cannot drift apart.
  Measured on demo data before being treated as real (the hub#138 gate):
  9 / 11 / 68 red-tier participants of 765 scored. [See them
  live](https://jwildfire.github.io/demo-301/#/safety/metric/saf0001).
- **[`SafetyCensus()`](https://jwildfire.github.io/gsm.safety/dev/reference/SafetyCensus.md)**
  (PR [\#47](https://github.com/jwildfire/gsm.safety/pull/47)) — reduces
  the mapped domains to the denominators a safety overview leads with:
  enrollment, exposure, person-years, deaths, and **data coverage per
  visit** — the figure that decides whether a quiet visit is reassuring
  or empty. New exported helpers behind the metrics:
  [`Input_HysLaw()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_HysLaw.md),
  [`Input_QtProlongation()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_QtProlongation.md),
  [`Input_SafetyAE()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_SafetyAE.md).
- **Report workflows move to `inst/workflow/4_modules/`**
  ([\#46](https://github.com/jwildfire/gsm.safety/issues/46), PR
  [\#47](https://github.com/jwildfire/gsm.safety/pull/47); hub
  [obot.roadmap#136](https://github.com/jwildfire/obot.roadmap/issues/136))
  — the standard gsm phase directory for `meta.Type: Report` workflows,
  the one gsm.kri already uses. Update any pipeline that globbed
  `3_reports/`.

1 286 tests pass; `R CMD check` clean.

## gsm.safety v1.0.0 and earlier

- [v1.0.0](https://github.com/jwildfire/gsm.safety/releases/tag/v1.0.0)
  — 2026-07-23.
- [gsm.safety
  v0.1.0](https://github.com/jwildfire/gsm.safety/releases/tag/v0.1.0) —
  2026-05-15.
