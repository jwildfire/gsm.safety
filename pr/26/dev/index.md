# gsm.safety

`gsm.safety` is an R package for generating clinical safety
visualization artifacts from Good Statistical Monitoring workflows.

The first release, `v0.1.0`, focuses on workflow-driven SafetyCharts
HTML widget reports. Reports are defined in YAML, run with
[`workr::RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.html),
and rendered with
[`gsm.safety::RenderSafetyChartsWidget()`](https://obot-claw.github.io/gsm.safety/dev/reference/RenderSafetyChartsWidget.md)
using reproducible `gsm.datasim`-backed example data.

## Current status

This repository contains:

- [Integration
  design](https://obot-claw.github.io/gsm.safety/dev/design/integration-design.md)
- [AE Explorer gap
  analysis](https://obot-claw.github.io/gsm.safety/dev/design/ae-explorer-gap-analysis.md)
- `workr`-shaped report workflows under `inst/workflow/3_reports/`
- Interactive SafetyCharts HTML report artifacts rendered through
  [`safetyCharts::render_widget()`](https://rdrr.io/pkg/safetyCharts/man/render_widget.html)
- Pkgdown examples that run the report YAML workflows with
  [`workr::RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.html)
- GitHub Actions R CMD check, pkgdown, coverage, and workflow-template
  checks

The package intentionally avoids wrapping the full SafetyGraphics Shiny
app. The current scope is standalone report artifacts that can be
generated from GSM-style mapped data. Nep Explorer is excluded from
`v0.1.0` because the legacy htmlwidget path is no longer supported;
future NEP support should be considered through a Shiny-app pipeline or
a static graphic.

## Available widget reports

| Widget report | Workflow YAML | Example |
|----|----|----|
| AE Explorer | [`ae_explorer.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/ae_explorer.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_AE_Explorer_Workflow.html) |
| AE Timelines | [`ae_timelines.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/ae_timelines.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_AE_Timelines_Workflow.html) |
| Hep Explorer | [`hep_explorer.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/hep_explorer.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_HepExplorer_Workflow.html) |
| Paneled Outlier Explorer | [`paneled_outlier_explorer.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/paneled_outlier_explorer.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_PaneledOutlierExplorer_Workflow.html) |
| Safety Delta Delta | [`safety_delta_delta.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_delta_delta.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_SafetyDeltaDelta_Workflow.html) |
| Safety Histogram | [`safety_histogram.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_histogram.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_SafetyHistogram_Workflow.html) |
| Safety Outlier Explorer | [`safety_outlier_explorer.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_outlier_explorer.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_SafetyOutlierExplorer_Workflow.html) |
| Safety Results Over Time | [`safety_results_over_time.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_results_over_time.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_SafetyResultsOverTime_Workflow.html) |
| Safety Shift Plot | [`safety_shift_plot.yaml`](https://obot-claw.github.io/gsm.safety/dev/inst/workflow/3_reports/safety_shift_plot.yaml) | [Example](https://obot-claw.github.io/gsm.safety/dev/menus/examples/Example_SafetyShiftPlot_Workflow.html) |

## Workflow approach

The implemented workflows keep the report contract in YAML and use
[`MakeExampleData()`](https://obot-claw.github.io/gsm.safety/dev/reference/MakeExampleData.md)
for reproducible examples:

1.  `meta$domains` maps GSM workflow data names, currently
    `Mapped_SUBJ`, `Mapped_AE`, and `Mapped_LB`, to the domain shapes
    expected by each SafetyCharts widget.
2.  `meta$widgetSettings` stores the widget column mapping used by
    `safetyCharts`, including `sex` as the current example grouping
    variable when supported.
3.  Workflows call the relevant `safetyCharts::init_*()` helper when one
    exists; widgets without an init helper pass data/settings directly
    to the renderer.
4.  [`gsm.safety::RenderSafetyChartsWidget()`](https://obot-claw.github.io/gsm.safety/dev/reference/RenderSafetyChartsWidget.md)
    renders the widget with
    [`safetyCharts::render_widget()`](https://rdrr.io/pkg/safetyCharts/man/render_widget.html)
    and writes a standalone HTML report.

The YAML is the authoritative configuration, and the generated HTML
widget is the report artifact.

## Development

This project intentionally does **not** use `renv` yet. The dependency
surface is still changing, and the first release should establish the
core package/API boundaries before adding lockfile maintenance.

Run the AE Explorer workflow example with:

``` r

source(system.file("examples", "run-ae-explorer-workflow.R", package = "gsm.safety"))
```

From a source checkout, use:

``` r

source("inst/examples/run-ae-explorer-workflow.R")
```

The pkgdown examples use
[`workr::RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.html)
against the workflow YAML files and render the returned htmlwidget
output.

Run local checks with:

``` r

rcmdcheck::rcmdcheck(args = "--no-manual")
```

or from a shell with R installed:

``` sh
R CMD check --no-manual gsm.safety
```

## Next milestones

1.  Merge PR \#26 and cut the first `v0.1.0` release with the available
    SafetyCharts widget reports.
2.  Harden the GSM-to-SafetyCharts mapping contract against real
    `gsm.mapping` outputs.
3.  Decide the dependency strategy for remote SafetyCharts/Tendril
    dependencies versus vendoring or reimplementation.
4.  Review FDA ST&F / Duke-Margolis materials and create issues for
    static safety displays.
5.  Revisit NEP support as a Shiny app pipeline or static graphic rather
    than as a legacy htmlwidget.

## License

Apache License 2.0.
