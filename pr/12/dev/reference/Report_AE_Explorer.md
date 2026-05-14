# Render an interactive AE Explorer report

Render an interactive AE Explorer report by validating mapped AE inputs,
initializing settings with
[`safetyCharts::init_aeExplorer()`](https://rdrr.io/pkg/safetyCharts/man/init_aeExplorer.html),
rendering the widget with
[`safetyCharts::render_widget()`](https://rdrr.io/pkg/safetyCharts/man/render_widget.html),
and writing a standalone HTML artifact for workflow and pkgdown
examples.

## Usage

``` r
Report_AE_Explorer(
  lData,
  lSettings,
  strOutputDir = getwd(),
  strOutputFile = "ae_explorer"
)
```

## Arguments

- lData:

  A named list containing `Mapped_SUBJ` and `Mapped_AE` data frames.

- lSettings:

  AE Explorer settings from
  [`MakeAeExplorerSettings()`](https://obot-claw.github.io/gsm.safety/dev/reference/MakeAeExplorerSettings.md).

- strOutputDir:

  Directory where the HTML report should be written.

- strOutputFile:

  Output file stem or filename. `.html` is appended when absent.

## Value

A list with the report path, htmlwidget, and summary tables.
