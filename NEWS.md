# gsm.safety 1.0.0

First stable release: gsm.safety is now the R home of the safety.viz interactive chart library, mirroring the gsm.kri / gsm.viz architecture.

## New features

- Nine interactive safety widgets built on the vendored safety.viz 1.4.0 bundle — a binding for every renderer the bundle exports: `Widget_Histogram()`, `Widget_ShiftPlot()`, `Widget_DeltaDelta()`, `Widget_ResultsOverTime()`, `Widget_OutlierExplorer()`, `Widget_AeTimelines()`, `Widget_AeExplorer()`, `Widget_HepExplorer()` (eDISH), and `Widget_QtExplorer()` (QT/QTc, safety.viz QT Explorer Phase 1).
- Every widget validates its inputs against the module's vendored JSON data contract (`inst/schema/`), so bad column mappings fail fast in R instead of silently in the browser.
- `ExampleData()` ships pharmaverseadam-derived demo datasets — `adbds` (long-format labs and vitals), `adae` (adverse events, carrying placeholder rows for AE-free participants so prevalence denominators cover the whole safety population), and `adeg` (ECG: QTcF, QTcB, and Heart Rate) — identical to the safety.viz site demos.
- `SaveWidgetReport()` writes any widget as a self-contained standalone HTML report.
- Report workflows under `inst/workflow/3_reports/` render each widget end-to-end via `gsm.core::RunWorkflow()`, with matching runner scripts in `inst/examples/`.

## Documentation

- A thumbnail gallery on the package home page links every widget to its live example page.
- Each example page shows the full report workflow that renders its chart — read from the installed package, so the listing is always the shipped YAML — collapsed by default.
- The example pages carry site chrome: a header band linking back to the package home, the reference index, and the safety.viz chart library, plus navigation across all nine examples generated from the pages themselves.

## Quality

- Full qcthat-style qualification: every test is traceable to its GitHub issue, covering widget contracts, input validation, standalone rendering, and workflow execution.

## Breaking changes

- The experimental safetyCharts bridge is retired: `RenderSafetyChartsWidget()`, `MakeExampleData()`, and the safetyCharts-era report scaffolds are removed, along with the safetyCharts and Tendril dependencies. The `ae_explorer` and `hep_explorer` report workflows return, rebuilt on the `Widget_*` pattern; `paneled_outlier_explorer` has no safety.viz module and is gone for good.
