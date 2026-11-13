# What each census metric published, verbatim

Every metric the report was configured to read, in the order it reads
them, with the numbers exactly as published — participant-days in days,
counts as counts — and, where a metric published nothing, a line saying
so.

## Usage

``` r
Report_CensusProvenance(dfResults, dfMetrics, lSettings)
```

## Arguments

- dfResults:

  `data.frame` The reporting model's results — `Reporting_Results`, one
  row per metric per group, carrying `MetricID`, `Numerator` and
  `Denominator`.

- dfMetrics:

  `data.frame` The reporting model's metric definitions —
  `Reporting_Metrics`, carrying `ID`, `MetricID`, `Metric` and the
  `Numerator` and `Denominator` labels.

- lSettings:

  `list` The report workflow's settings: `Sections`, each a `Title` and
  the `Metrics` read out under it, and `PersonTime`, naming the metric
  IDs published in days along with `DaysPerYear` and the `Unit` to
  present them in.

## Value

`data.frame`, one row per metric named in `lSettings`, with columns
`ID`, `Figure`, `Numerator`, `Denominator` and `Status`.

## Details

This table is what makes the report auditable. The figures table
presents; this one records. A reader who wants to check that the
exposure figure was divided rather than recounted can read the days here
and the years there, and a metric that stopped because a study supplies
no such domain is named rather than silently missing.

## Three states, kept apart

`Status` distinguishes the three states the census metrics are built to
keep apart. **published** is a figure, and a published `0` is a
measurement. **no row published** is a metric that ran and measured
nothing — the domain was absent or empty, and it stopped rather than
reporting a zero. **not run for this study** is a metric the report was
told to read that this study's reporting model does not carry at all:
the study never ran it. On any study with no ECG domain that is
`saf0011`, because a batch that includes it stops on the missing domain
rather than publishing a zero.

## Examples

``` r
Report_CensusProvenance(
  dfResults = data.frame(
    MetricID = "Analysis_saf0008", GroupID = "AA-AA-000-0000",
    Numerator = 26754, Denominator = 762, Flag = NA_integer_
  ),
  dfMetrics = data.frame(
    ID = c("saf0008", "saf0011"),
    MetricID = c("Analysis_saf0008", "Analysis_saf0011"),
    Metric = c(
      "Participant-Days on Study (Study)", "Participants With an ECG (Study)"
    )
  ),
  lSettings = list(
    Sections = list(
      list(Title = "Exposure", Metrics = list("saf0008", "saf0011"))
    )
  )
)
#>        ID                            Figure Numerator Denominator
#> 1 saf0008 Participant-Days on Study (Study)     26754         762
#> 2 saf0011  Participants With an ECG (Study)        NA          NA
#>             Status
#> 1        published
#> 2 no row published
```
