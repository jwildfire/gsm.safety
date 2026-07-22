# Changelog

## gsm.safety 1.0.0

First stable release: gsm.safety is now the R home of the safety.viz
interactive chart library, mirroring the gsm.kri / gsm.viz architecture.

### New features

- Nine interactive safety widgets built on the vendored safety.viz 1.4.0
  bundle — a binding for every renderer the bundle exports:
  [`Widget_Histogram()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_Histogram.md),
  [`Widget_ShiftPlot()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ShiftPlot.md),
  [`Widget_DeltaDelta()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_DeltaDelta.md),
  [`Widget_ResultsOverTime()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ResultsOverTime.md),
  [`Widget_OutlierExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_OutlierExplorer.md),
  [`Widget_AeTimelines()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_AeTimelines.md),
  [`Widget_AeExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_AeExplorer.md),
  [`Widget_HepExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_HepExplorer.md)
  (eDISH), and
  [`Widget_QtExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_QtExplorer.md)
  (QT/QTc, safety.viz QT Explorer Phase 1).
- Every widget validates its inputs against the module’s vendored JSON
  data contract (`inst/schema/`), so bad column mappings fail fast in R
  instead of silently in the browser.
- [`ExampleData()`](https://jwildfire.github.io/gsm.safety/dev/reference/ExampleData.md)
  ships pharmaverseadam-derived demo datasets — `adbds` (long-format
  labs and vitals), `adae` (adverse events, carrying placeholder rows
  for AE-free participants so prevalence denominators cover the whole
  safety population), and `adeg` (ECG: QTcF, QTcB, and Heart Rate) —
  identical to the safety.viz site demos.
- [`SaveWidgetReport()`](https://jwildfire.github.io/gsm.safety/dev/reference/SaveWidgetReport.md)
  writes any widget as a self-contained standalone HTML report.
- Report workflows under `inst/workflow/3_reports/` render each widget
  end-to-end via
  [`gsm.core::RunWorkflow()`](https://gilead-biostats.github.io/gsm.core/reference/RunWorkflow.html),
  with matching runner scripts in `inst/examples/`.

### Quality

- Full qcthat-style qualification: every test is traceable to its GitHub
  issue, covering widget contracts, input validation, standalone
  rendering, and workflow execution.

### Breaking changes

- The experimental safetyCharts bridge is retired:
  `RenderSafetyChartsWidget()`, `MakeExampleData()`, and the
  safetyCharts-era report scaffolds are removed, along with the
  safetyCharts and Tendril dependencies. The `ae_explorer` and
  `hep_explorer` report workflows return, rebuilt on the `Widget_*`
  pattern; `paneled_outlier_explorer` has no safety.viz module and is
  gone for good.
