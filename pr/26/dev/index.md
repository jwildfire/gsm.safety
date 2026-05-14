# gsm.safety

`gsm.safety` is an early-stage R package concept for bringing clinical
safety visualizations inspired by the SafetyGraphics ecosystem into Good
Statistical Monitoring (`gsm.core`) workflows.

Initial direction: build a lightweight GSM extension/plugin package that
bridges GSM `lData` objects and mapped domains (`Mapped_SUBJ`,
`Mapped_AE`, `Mapped_LB`, etc.) to selected SafetyGraphics-style chart
artifacts. Avoid forking the full `safetyGraphics` Shiny app; start with
workflow-generated report artifacts and optional `gsm.app` plugins
later.

## Current status

This repository is a newly scaffolded prototype package. It currently
contains:

- [Integration
  design](https://obot-claw.github.io/gsm.safety/dev/design/integration-design.md)
- [AE Explorer gap
  analysis](https://obot-claw.github.io/gsm.safety/dev/design/ae-explorer-gap-analysis.md)
- `workr`-shaped report workflows under `inst/workflow/3_reports/` for
  AE Explorer, AE Timelines, Hep Explorer, Nep Explorer, Paneled Outlier
  Explorer, Safety Delta Delta, Safety Histogram, Safety Outlier
  Explorer, Safety Results Over Time, and Safety Shift Plot
- Interactive SafetyCharts HTML report artifacts rendered through
  [`safetyCharts::render_widget()`](https://rdrr.io/pkg/safetyCharts/man/render_widget.html)
- Pkgdown menu examples that run the report YAML workflows with
  [`workr::RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.html)
- GitHub Actions R CMD check, pkgdown, coverage, and workflow-template
  checks

The implemented workflows keep the report contract in YAML and use
[`MakeExampleData()`](https://obot-claw.github.io/gsm.safety/dev/reference/MakeExampleData.md)
for reproducible `gsm.datasim`-backed examples:

1.  `meta$domains` maps GSM workflow data names, currently
    `Mapped_SUBJ`, `Mapped_AE`, and `Mapped_LB`, to the domain shapes
    expected by each `safetyCharts` widget.
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

The YAML is now the authoritative configuration, and the generated HTML
widget is the report artifact. The next milestone is to harden the
GSM-to-SafetyCharts mapping contract against real `gsm.mapping` outputs
and continue hardening the `gsm.datasim`-based example data path.

## Development

This project intentionally does **not** use `renv` yet. The dependency
surface is still changing, and the MVP should first establish the core
package/API boundaries before adding lockfile maintenance.

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

## Proposed MVP

1.  Define a minimal package skeleton.
2.  Implement data-contract adapters from GSM mapped data to
    SafetyGraphics-style `domainData`.
3.  Render one AE-focused chart artifact from `Mapped_SUBJ` +
    `Mapped_AE` through a `gsm.core` workflow module.
4.  Add validation, tests, and a small reproducible fixture.

## License

Apache License 2.0.
