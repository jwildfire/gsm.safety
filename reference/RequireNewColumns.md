# Require that a derivation's output columns are new

The `Derive_*` functions return the input frame with their columns
appended, dropping and replacing nothing. An output name that already
exists in the frame would be overwritten silently, so it is refused.

## Usage

``` r
RequireNewColumns(df, chrOutCols, strName = "dfResults")
```

## Arguments

- df:

  `data.frame` The input frame.

- chrOutCols:

  `character` The names the derivation is about to add.

- strName:

  `character` Name of the argument, for the message.
