# Warn once, naming every deprecated argument the caller supplied

Deprecated and ignored, not removed (D0023.5, approved): the release
changes what the numbers say and nothing about how they are read, so a
call that passed one of these still runs.

## Usage

``` r
.WarnDeprecatedCensusArgs(bSupplied)
```

## Arguments

- bSupplied:

  Named `logical` — one element per deprecated argument, `TRUE` where
  the caller supplied it.

## Value

`NULL`, invisibly. Called for the warning.
