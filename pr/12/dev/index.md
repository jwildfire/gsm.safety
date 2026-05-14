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
- A `workr`-shaped AE Explorer report workflow at
  `inst/workflow/3_reports/ae_explorer.yaml`
- An interactive SafetyCharts AE Explorer HTML report artifact
- Pkgdown menu examples for both direct widget rendering and YAML-driven
  workflow execution
- GitHub Actions R CMD check, pkgdown, coverage, and workflow-template
  checks

The first implemented workflow keeps the report contract in YAML and
uses
[`MakeExampleData()`](https://obot-claw.github.io/gsm.safety/dev/reference/MakeExampleData.md)
for reproducible `gsm.datasim`-backed examples:

1.  `meta$domains` maps GSM workflow data names, currently `Mapped_SUBJ`
    and `Mapped_AE`, to the `safetyCharts` AE Explorer domain names `dm`
    and `aes`.
2.  `meta$widgetSettings` stores the AE Explorer column mapping used by
    `safetyCharts`, including `sex` as the current AE Explorer grouping
    variable.
3.  The workflow creates the `list(dm = Mapped_SUBJ, aes = Mapped_AE)`
    structure expected by `safetyCharts` directly in YAML.
4.  [`safetyCharts::init_aeExplorer()`](https://rdrr.io/pkg/safetyCharts/man/init_aeExplorer.html)
    initializes the widget data/settings.
5.  [`gsm.safety::RenderAeExplorerWidget()`](https://obot-claw.github.io/gsm.safety/dev/reference/RenderAeExplorerWidget.md)
    renders the initialized widget with
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

The pkgdown examples mirror those two supported paths:

- direct render: read the YAML settings, call
  [`safetyCharts::init_aeExplorer()`](https://rdrr.io/pkg/safetyCharts/man/init_aeExplorer.html),
  then save the widget.
- workflow render: call
  [`workr::RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.html)
  using `inst/workflow/3_reports/ae_explorer.yaml`.

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
