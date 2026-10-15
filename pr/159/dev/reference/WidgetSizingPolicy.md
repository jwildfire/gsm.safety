# Default sizing policy for gsm.safety widgets

The safety.viz shell lays out as a normal document (sticky sidebar plus
full-width charts), so the widgets default to the full container width
rather than htmlwidgets' fixed 960px.

## Usage

``` r
WidgetSizingPolicy()
```

## Value

An
[`htmlwidgets::sizingPolicy()`](https://rdrr.io/pkg/htmlwidgets/man/sizingPolicy.html).
