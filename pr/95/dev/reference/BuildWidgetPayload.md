# Build the htmlwidget payload for a safety.viz module

Validates the supplied data and `lSettings` against the module's
vendored JSON data contract (`inst/schema/<strModule>.json`): every
required settings key must resolve (from `lSettings` or the schema
default), and every column-mapping setting (`*_col`) referenced by a
required key must name a column of the data.

## Usage

``` r
BuildWidgetPayload(
  dfResults,
  lSettings = list(),
  strModule,
  bDebug = FALSE,
  lData = NULL
)
```

## Arguments

- dfResults:

  `data.frame` Long-format results data, one record per row. The whole
  input for a single-dataset contract; unused when `lData` is supplied.

- lSettings:

  `list` safety.viz settings overrides; merged onto the module's
  `DEFAULT_SETTINGS` client-side, so only overrides are needed.

- strModule:

  `character` Module slug matching a schema file, e.g. `"histogram"` or
  `"shift-plot"`.

- bDebug:

  `logical` Print debug messages in the browser console? Default:
  `FALSE`.

- lData:

  `list` Named list of `data.frame`s for a multi-dataset contract, keyed
  by the contract's dataset names (e.g. `events` and `population`).
  Default: `NULL`, meaning `dfResults` is the single dataset.

## Value

`list` — the `x` payload for
[`htmlwidgets::createWidget()`](https://rdrr.io/pkg/htmlwidgets/man/createWidget.html).
Carries `dfResults`, `lSettings` and `bDebug` for a single-dataset
contract, and `lData`, `lSettings` and `bDebug` for a multi-dataset one.

## Details

Most contracts name a single dataset (`data`), which arrives as
`dfResults`. Some name more than one — `time-to-event` composes its
endpoint from `events` plus `population` — and those arrive as `lData`,
a named list keyed by the contract's own dataset names. The dataset
names are read off the schema rather than assumed, so a module that
grows a third frame upstream needs no change here. Where a dataset
declares its own `requiredSettings`, those column mappings are checked
against *that* frame: naming the population's follow-up column in the
events data is an error, not a silent empty chart.
