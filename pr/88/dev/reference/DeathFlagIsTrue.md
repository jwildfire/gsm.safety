# Is a death flag true, whichever way the study spells it?

`Mapped_Death$death` is logical by spec, but a study can arrive with the
column as a character or numeric flag. Missing is never true: a row
carried for some other reason must not read as a death.

## Usage

``` r
DeathFlagIsTrue(x)
```

## Arguments

- x:

  Vector to read as a death flag.

## Value

`logical` of `length(x)`.
