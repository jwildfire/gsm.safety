# Example safety data

Reads one of the example datasets vendored with the package. All three
are derived from pharmaverseadam (CDISC Pilot 01 ADaM) and match the
data used by the safety.viz demos:

## Usage

``` r
ExampleData(strDataset = c("adbds", "adae", "adeg"))
```

## Arguments

- strDataset:

  `character` Name of the example dataset to read. Default: `"adbds"`.

## Value

A `data.frame` with numeric result/range/day columns and character
columns otherwise.

## Details

- `adbds`: long-format BDS labs and vitals results, one record per
  measurement (`USUBJID`, `SITE`, `SITEID`, `SEX`, `RACE`, `ARM`,
  `VISIT`, `VISITNUM`, `TEST`, `STRESU`, `STRESN`, `STNRLO`, `STNRHI`).

- `adae`: adverse events, one record per event (`USUBJID`, `ARM`,
  `AESEQ`, `AEBODSYS`, `AEDECOD`, `AETERM`, `AESEV`, `AESER`, `ASTDY`,
  `AENDY`), plus one placeholder row per participant with no adverse
  events. A placeholder carries a blank `AEBODSYS` and exists so the
  [`Widget_AeExplorer()`](https://jwildfire.github.io/gsm.safety/reference/Widget_AeExplorer.md)
  population denominator covers the whole safety population (254
  participants, 217 of them with events) rather than only participants
  who reported an event.

- `adeg`: long-format ECG results, one record per measurement
  (`USUBJID`, `SITE`, `SITEID`, `SEX`, `RACE`, `AGE`, `ARM`, `VISIT`,
  `VISITNUM`, `PARAMCD`, `TEST`, `STRESU`, `STRESN`, `BASE`, `CHG`,
  `ABLFL`), carrying QTcF, QTcB, and Heart Rate for
  [`Widget_QtExplorer()`](https://jwildfire.github.io/gsm.safety/reference/Widget_QtExplorer.md).

## Examples

``` r
dfResults <- ExampleData("adbds")
head(dfResults)
#>       USUBJID              SITE SITEID SEX  RACE     ARM    VISIT VISITNUM
#> 1 01-701-1015 Clinical Site 701    701   F WHITE Placebo Baseline        0
#> 2 01-701-1015 Clinical Site 701    701   F WHITE Placebo   Week 2        4
#> 3 01-701-1015 Clinical Site 701    701   F WHITE Placebo   Week 4        5
#> 4 01-701-1015 Clinical Site 701    701   F WHITE Placebo   Week 6        7
#> 5 01-701-1015 Clinical Site 701    701   F WHITE Placebo   Week 8        8
#> 6 01-701-1015 Clinical Site 701    701   F WHITE Placebo  Week 12        9
#>      TEST STRESU STRESN STNRLO STNRHI
#> 1 Albumin    g/L     38     33     49
#> 2 Albumin    g/L     39     33     49
#> 3 Albumin    g/L     38     33     49
#> 4 Albumin    g/L     37     33     49
#> 5 Albumin    g/L     38     33     49
#> 6 Albumin    g/L     38     33     49

dfAE <- ExampleData("adae")
head(dfAE)
#>       USUBJID     ARM AESEQ
#> 1 01-701-1015 Placebo     1
#> 2 01-701-1015 Placebo     2
#> 3 01-701-1015 Placebo     3
#> 4 01-701-1023 Placebo     2
#> 5 01-701-1023 Placebo     1
#> 6 01-701-1023 Placebo     4
#>                                               AEBODSYS
#> 1 GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS
#> 2 GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS
#> 3                           GASTROINTESTINAL DISORDERS
#> 4               SKIN AND SUBCUTANEOUS TISSUE DISORDERS
#> 5               SKIN AND SUBCUTANEOUS TISSUE DISORDERS
#> 6               SKIN AND SUBCUTANEOUS TISSUE DISORDERS
#>                     AEDECOD                    AETERM    AESEV AESER ASTDY
#> 1 APPLICATION SITE ERYTHEMA APPLICATION SITE ERYTHEMA     MILD     N     2
#> 2 APPLICATION SITE PRURITUS APPLICATION SITE PRURITUS     MILD     N     2
#> 3                 DIARRHOEA                 DIARRHOEA     MILD     N     8
#> 4                  ERYTHEMA                  ERYTHEMA MODERATE     N     3
#> 5                  ERYTHEMA                  ERYTHEMA     MILD     N     3
#> 6                  ERYTHEMA                  ERYTHEMA     MILD     N     3
#>   AENDY
#> 1    NA
#> 2    NA
#> 3    10
#> 4    NA
#> 5    26
#> 6    26

dfEG <- ExampleData("adeg")
head(dfEG)
#>       USUBJID              SITE SITEID SEX  RACE AGE     ARM    VISIT VISITNUM
#> 1 01-701-1015 Clinical Site 701    701   F WHITE  63 Placebo Baseline        0
#> 2 01-701-1015 Clinical Site 701    701   F WHITE  63 Placebo   Week 2        2
#> 3 01-701-1015 Clinical Site 701    701   F WHITE  63 Placebo   Week 4        4
#> 4 01-701-1015 Clinical Site 701    701   F WHITE  63 Placebo   Week 6        6
#> 5 01-701-1015 Clinical Site 701    701   F WHITE  63 Placebo   Week 8        8
#> 6 01-701-1015 Clinical Site 701    701   F WHITE  63 Placebo  Week 12       12
#>   PARAMCD TEST STRESU STRESN  BASE  CHG ABLFL
#> 1    QTCF QTcF   msec  328.4 328.4  0.0     Y
#> 2    QTCF QTcF   msec  332.2 328.4  3.8      
#> 3    QTCF QTcF   msec  381.9 328.4 53.5      
#> 4    QTCF QTcF   msec  320.6 328.4 -7.8      
#> 5    QTCF QTcF   msec  395.2 328.4 66.8      
#> 6    QTCF QTcF   msec  393.9 328.4 65.5      
```
