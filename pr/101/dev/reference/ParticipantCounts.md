# Which rows of a domain count towards a census figure?

Three cases, and the difference between them is the whole
configurability of the counting metrics: no filter column counts every
row; a filter column with no values counts a row that *records*
something; a filter column with values counts a row that matches one of
them.

## Usage

``` r
ParticipantCounts(dfDomain, strFilterCol = NULL, strFilterValues = NULL)
```

## Arguments

- dfDomain:

  `data.frame` Domain being counted.

- strFilterCol:

  `character` or `NULL` Deciding column.

- strFilterValues:

  `character` or `NULL` Values that count, comma separated, compared
  without regard to case or surrounding space.

## Value

`logical` of `nrow(dfDomain)`.

## Details

Missing is never a match. A row carried for some other reason, or one
whose completion flag was never filled in, must not read as a
completion.
