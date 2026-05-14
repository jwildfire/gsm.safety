# Save an initialized AE Explorer widget as standalone HTML

Save an initialized AE Explorer widget as standalone HTML

## Usage

``` r
RenderAeExplorerWidget(
  lInitialized,
  strOutputDir = getwd(),
  strOutputFile = "ae_explorer"
)
```

## Arguments

- lInitialized:

  A list returned by
  [`safetyCharts::init_aeExplorer()`](https://rdrr.io/pkg/safetyCharts/man/init_aeExplorer.html).

- strOutputDir:

  Directory where the HTML report should be written.

- strOutputFile:

  Output file stem or filename. `.html` is appended when absent.

## Value

A list with the report path and htmlwidget.
