# Stop unless every named column is present

Stop unless every named column is present

## Usage

``` r
.RequireColumns(df, chrCols, strName)
```

## Arguments

- df:

  `data.frame` to check.

- chrCols:

  `character` Columns that must be present. `NULL` entries are dropped,
  so an optional column can be passed straight through.

- strName:

  `character` Domain name for the message.

## Value

`NULL`, invisibly. Called for the error.
