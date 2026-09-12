# Refuse to present a flagged result as a census figure

D0023.3 — no census number raises anything, and the metrics enforce that
by declaring no threshold and calling
[`Flag_None()`](https://jwildfire.github.io/gsm.safety/dev/reference/Flag_None.md).
A result that arrives carrying a flag did not come from a census metric,
and presenting it on a page that shows no flags would hide a signal
rather than describe a study. It stops.

## Usage

``` r
RefuseFlaggedResults(dfResults, chrIDs = character(0))
```

## Arguments

- dfResults:

  `data.frame` Rows about to be presented.

- chrIDs:

  `character` Metric IDs they belong to, for the message.

## Value

`NULL`, invisibly.
