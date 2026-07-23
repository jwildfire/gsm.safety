# Build the htmlwidget payload for a safety.viz module

Validates `dfResults` and `lSettings` against the module's vendored JSON
data contract (`inst/schema/<strModule>.json`): every required settings
key must resolve (from `lSettings` or the schema default), and every
column-mapping setting (`*_col`) referenced by a required key must name
a column of `dfResults`.

## Usage

``` r
BuildWidgetPayload(dfResults, lSettings = list(), strModule, bDebug = FALSE)
```

## Arguments

- dfResults:

  `data.frame` Long-format results data, one record per row.

- lSettings:

  `list` safety.viz settings overrides; merged onto the module's
  `DEFAULT_SETTINGS` client-side, so only overrides are needed.

- strModule:

  `character` Module slug matching a schema file, e.g. `"histogram"` or
  `"shift-plot"`.

- bDebug:

  `logical` Print debug messages in the browser console? Default:
  `FALSE`.

## Value

`list` with `dfResults`, `lSettings`, and `bDebug` — the `x` payload for
[`htmlwidgets::createWidget()`](https://rdrr.io/pkg/htmlwidgets/man/createWidget.html).
