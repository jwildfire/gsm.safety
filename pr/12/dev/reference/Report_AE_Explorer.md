# Render an interactive AE Explorer report

Render an interactive AE Explorer report with
[`safetyCharts::aeExplorer()`](https://rdrr.io/pkg/safetyCharts/man/aeExplorer.html),
validate mapped AE inputs, and write a standalone HTML artifact for
workflow and pkgdown examples.

## Usage

``` r
Report_AE_Explorer(
  lData,
  lSettings,
  lManifest,
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

- lManifest:

  AE Explorer manifest from
  [`MakeAeExplorerManifest()`](https://obot-claw.github.io/gsm.safety/dev/reference/MakeAeExplorerManifest.md).

- strOutputDir:

  Directory where the HTML report should be written.

- strOutputFile:

  Output file stem or filename. `.html` is appended when absent.

## Value

A list with the report path, htmlwidget, manifest, and summary tables.
