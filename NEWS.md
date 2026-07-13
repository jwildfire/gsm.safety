# gsm.safety 1.0.0

First stable release: gsm.safety is now the R home of the safety.viz interactive chart library, mirroring the gsm.kri / gsm.viz architecture.

## New features

- Seven interactive safety widgets built on the vendored safety.viz 1.2.0 bundle: `Widget_Histogram()`, `Widget_ShiftPlot()`, `Widget_DeltaDelta()`, `Widget_ResultsOverTime()`, `Widget_OutlierExplorer()`, `Widget_AeTimelines()`, and `Widget_HepExplorer()` (eDISH).
- Every widget validates its inputs against the module's vendored JSON data contract (`inst/schema/`), so bad column mappings fail fast in R instead of silently in the browser.
- `ExampleData()` ships pharmaverseadam-derived demo datasets — `adbds` (long-format labs and vitals) and `adae` (adverse events) — identical to the safety.viz site demos.
- `SaveWidgetReport()` writes any widget as a self-contained standalone HTML report.
- Report workflows under `inst/workflow/3_reports/` render each widget end-to-end via `gsm.core::RunWorkflow()`, with matching runner scripts in `inst/examples/`.

## Quality

- Full qcthat-style qualification: every test is traceable to its GitHub issue, covering widget contracts, input validation, standalone rendering, and workflow execution.

## Breaking changes

- The experimental safetyCharts bridge is retired: `RenderSafetyChartsWidget()`, `MakeExampleData()`, and the safetyCharts-era report scaffolds (ae_explorer, hep_explorer, paneled_outlier_explorer) are removed, along with the safetyCharts and Tendril dependencies.
