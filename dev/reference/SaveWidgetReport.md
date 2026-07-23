# Save a safety widget as a standalone HTML report

Wraps
[`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html)
to write a self-contained HTML report, creating the output directory
when needed and appending `.html` to the file name when absent.

## Usage

``` r
SaveWidgetReport(widget, strOutputDir = getwd(), strOutputFile)
```

## Arguments

- widget:

  `htmlwidget` The widget to save, e.g. from
  [`Widget_Histogram()`](https://jwildfire.github.io/gsm.safety/dev/reference/Widget_Histogram.md).

- strOutputDir:

  `character` Directory where the report is written. Default:
  [`getwd()`](https://rdrr.io/r/base/getwd.html).

- strOutputFile:

  `character` Output file stem or filename.

## Value

The normalized path to the saved report, invisibly.

## Examples

``` r
dfResults <- ExampleData("adbds")
strReportPath <- SaveWidgetReport(
  Widget_Histogram(dfResults[dfResults$TEST == "Albumin", ]),
  strOutputDir = tempdir(),
  strOutputFile = "histogram"
)
```
