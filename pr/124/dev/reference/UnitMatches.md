# Does a record's unit match a criteria row's unit?

Spellings are folded by
[`NormaliseUnit()`](https://jwildfire.github.io/gsm.safety/dev/reference/NormaliseUnit.md);
mEq/L and mmol/L are treated as the same unit only for the monovalent
parameters in
[CHR_MONOVALENT](https://jwildfire.github.io/gsm.safety/dev/reference/CHR_MONOVALENT.md).
Nothing is converted.

## Usage

``` r
UnitMatches(chrDataUnit, strCriteriaUnit, strParameter)
```

## Arguments

- chrDataUnit:

  `character` The records' units, already normalised.

- strCriteriaUnit:

  `character` The criteria row's unit, as printed.

- strParameter:

  `character` The criteria row's parameter.

## Value

`logical` of `length(chrDataUnit)`; `FALSE` where the data unit is `NA`.
