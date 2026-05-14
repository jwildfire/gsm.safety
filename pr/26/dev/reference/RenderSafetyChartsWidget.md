# Save an initialized safetyCharts widget as standalone HTML

Save an initialized safetyCharts widget as standalone HTML

## Usage

``` r
RenderSafetyChartsWidget(
  lInitialized,
  strWidgetName,
  strOutputDir = getwd(),
  strOutputFile = strWidgetName
)
```

## Arguments

- lInitialized:

  A list returned by a `safetyCharts::init_*()` helper with `data` and
  `settings` entries.

- strWidgetName:

  Name of the safetyCharts htmlwidget to render.

- strOutputDir:

  Directory where the HTML report should be written.

- strOutputFile:

  Output file stem or filename. `.html` is appended when absent.

## Value

A list with the report path and htmlwidget.
