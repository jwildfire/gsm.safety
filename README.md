# gsm.safety

`gsm.safety` provides R bindings for the [safety.viz](https://github.com/jwildfire/safety.viz) JavaScript chart library: six interactive clinical safety displays as htmlwidgets, plus bundled example data and report workflows for Good Statistical Monitoring. It mirrors the `gsm.kri` / `gsm.viz` architecture.

## Widgets

| Widget | safety.viz module | Report workflow |
|---|---|---|
| `Widget_Histogram()` | histogram | [`safety_histogram.yaml`](inst/workflow/3_reports/safety_histogram.yaml) |
| `Widget_ShiftPlot()` | shiftPlot | [`safety_shift_plot.yaml`](inst/workflow/3_reports/safety_shift_plot.yaml) |
| `Widget_DeltaDelta()` | deltaDelta | [`safety_delta_delta.yaml`](inst/workflow/3_reports/safety_delta_delta.yaml) |
| `Widget_ResultsOverTime()` | resultsOverTime | [`safety_results_over_time.yaml`](inst/workflow/3_reports/safety_results_over_time.yaml) |
| `Widget_OutlierExplorer()` | outlierExplorer | [`safety_outlier_explorer.yaml`](inst/workflow/3_reports/safety_outlier_explorer.yaml) |
| `Widget_AeTimelines()` | aeTimelines | [`ae_timelines.yaml`](inst/workflow/3_reports/ae_timelines.yaml) |

Each widget validates its data and settings against the module's vendored JSON data contract (`inst/schema/`) before rendering, so column-mapping mistakes fail fast in R.

## Usage

```r
library(gsm.safety)

# Bundled pharmaverseadam-derived demo data (same data as the safety.viz site demos)
dfResults <- ExampleData("adbds") # long-format labs and vitals
dfAE <- ExampleData("adae") # adverse events

# Render a widget in the viewer
Widget_Histogram(dfResults, lSettings = list(group_by = "ARM"))

# Or save any widget as a self-contained HTML report
SaveWidgetReport(
  Widget_Histogram(dfResults),
  strOutputDir = tempdir(),
  strOutputFile = "histogram"
)
```

Settings are merged onto each module's defaults client-side, so only overrides are needed; the defaults already match the example data column names.

## Report workflows

Report workflows under `inst/workflow/3_reports/` render each widget end-to-end via `gsm.core::RunWorkflow()`. Matching runner scripts live in `inst/examples/`:

```sh
Rscript inst/examples/histogram.R [output_dir]
```

## Development

```r
devtools::test()
devtools::check()
```

## License

Apache License 2.0.
