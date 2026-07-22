# gsm.safety

`gsm.safety` provides R bindings for the
[safety.viz](https://github.com/jwildfire/safety.viz) JavaScript chart
library: nine interactive clinical safety displays as htmlwidgets — one
for every renderer the library ships — plus bundled example data and
report workflows for Good Statistical Monitoring. It mirrors the
`gsm.kri` / `gsm.viz` architecture.

## Gallery

Each thumbnail links to a live, interactive example rendered from the
bundled demo data.

[TABLE]

## Widgets

| Widget | safety.viz module | Data | Report workflow |
|----|----|----|----|
| [`Widget_Histogram()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_Histogram.md) | histogram | `adbds` | [`safety_histogram.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_histogram.yaml) |
| [`Widget_ShiftPlot()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ShiftPlot.md) | shiftPlot | `adbds` | [`safety_shift_plot.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_shift_plot.yaml) |
| [`Widget_DeltaDelta()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_DeltaDelta.md) | deltaDelta | `adbds` | [`safety_delta_delta.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_delta_delta.yaml) |
| [`Widget_ResultsOverTime()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_ResultsOverTime.md) | resultsOverTime | `adbds` | [`safety_results_over_time.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_results_over_time.yaml) |
| [`Widget_OutlierExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_OutlierExplorer.md) | outlierExplorer | `adbds` | [`safety_outlier_explorer.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_outlier_explorer.yaml) |
| [`Widget_AeTimelines()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_AeTimelines.md) | aeTimelines | `adae` | [`ae_timelines.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/ae_timelines.yaml) |
| [`Widget_AeExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_AeExplorer.md) | aeExplorer | `adae` | [`ae_explorer.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/ae_explorer.yaml) |
| [`Widget_HepExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_HepExplorer.md) | hepExplorer | `adbds` | [`hep_explorer.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/hep_explorer.yaml) |
| [`Widget_QtExplorer()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_QtExplorer.md) | qtExplorer | `adeg` | [`qt_explorer.yaml`](https://jwildfire.github.io/gsm.safety/dev/inst/workflow/3_reports/qt_explorer.yaml) |

Each widget validates its data and settings against the module’s
vendored JSON data contract (`inst/schema/`) before rendering, so
column-mapping mistakes fail fast in R.

## Usage

``` r

library(gsm.safety)

# Bundled pharmaverseadam-derived demo data (same data as the safety.viz site demos)
dfResults <- ExampleData("adbds") # long-format labs and vitals
dfAE <- ExampleData("adae") # adverse events
dfEG <- ExampleData("adeg") # ECG: QTcF, QTcB, heart rate

# Render a widget in the viewer
Widget_Histogram(dfResults, lSettings = list(group_by = "ARM"))

# Or save any widget as a self-contained HTML report
SaveWidgetReport(
  Widget_Histogram(dfResults),
  strOutputDir = tempdir(),
  strOutputFile = "histogram"
)
```

Settings are merged onto each module’s defaults client-side, so only
overrides are needed; the defaults already match the example data column
names.

## Report workflows

Report workflows under `inst/workflow/3_reports/` render each widget
end-to-end via
[`gsm.core::RunWorkflow()`](https://gilead-biostats.github.io/gsm.core/reference/RunWorkflow.html).
Matching runner scripts live in `inst/examples/`:

``` sh
Rscript inst/examples/histogram.R [output_dir]
```

## Development

``` r

devtools::test()
devtools::check()
```

The gallery thumbnails in `man/figures/widgets/` are vendored
byte-identical from the safety.viz release assets — the canonical
headless-Chromium captures that repo publishes for its own gallery.
Refresh them whenever the vendored bundle is bumped:

``` sh
tools/vendor-widget-thumbnails.sh [path-to-safety.viz-checkout]
```

## License

Apache License 2.0.
