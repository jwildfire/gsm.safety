# Publish a metric's rows without a flag

The step a **descriptive** metric calls where a flagging metric calls
[`gsm.core::Flag()`](https://rdrr.io/pkg/gsm.core/man/Flag.html). It
adds the `Flag` column
[`gsm.core::Summarize()`](https://rdrr.io/pkg/gsm.core/man/Summarize.html)
requires and leaves it empty.

## Usage

``` r
Flag_None(dfAnalyzed)
```

## Arguments

- dfAnalyzed:

  `data.frame` Output of an `Analyze_*` step, carrying at least `Score`.

## Value

`dfAnalyzed` with an integer `Flag` column of `NA`.

## Details

Empty, not zero. `0` is a flag value that means *measured and found
fine* — a green light. `NA` is the ecosystem's existing way of saying
this number does not flag: gsm.kri's `srs0001` site risk score has
published its rows that way in production throughout, declaring no
threshold and calling no flagging step. Because a metric with no
threshold contributes no weights, `gsm.kri`'s risk-score builder skips
it automatically, so a descriptive metric cannot move a site's risk
score.

## Examples

``` r
dfAnalyzed <- data.frame(
  GroupID = "AA-AA-000-0000", GroupLevel = "Study",
  Numerator = 12, Denominator = 760, Metric = 12 / 760, Score = 12
)
Flag_None(dfAnalyzed)
#>          GroupID GroupLevel Numerator Denominator     Metric Score Flag
#> 1 AA-AA-000-0000      Study        12         760 0.01578947    12   NA
```
