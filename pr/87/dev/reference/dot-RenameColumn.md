# Rename one column, dropping whatever already held the target name

Rename one column, dropping whatever already held the target name

## Usage

``` r
.RenameColumn(df, strFrom, strTo)
```

## Arguments

- df:

  `data.frame` to rename in.

- strFrom, strTo:

  `character` Column names.

## Value

`df`, with `strFrom` renamed to `strTo` where it was present.
