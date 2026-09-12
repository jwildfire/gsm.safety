# The mapped domains, keyed the way the metric definitions declare them

The mapped domains, keyed the way the metric definitions declare them

## Usage

``` r
.CensusDomains(lDomains, strIDCol, strGroupCol)
```

## Arguments

- lDomains:

  Named `list` of the domains as they arrived, `NULL` where the caller
  supplied none.

- strIDCol:

  `character` Participant ID column the caller keys on.

- strGroupCol:

  `character` Study identifier column in `Mapped_SUBJ`.

## Value

Named `list` of the supplied domains only.
