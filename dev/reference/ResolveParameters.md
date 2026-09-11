# Resolve each record's test name to a reference-table parameter

`lParameterValues` maps a reference-table `Parameter` to the test name
(or names) the data use for it, the way `lMeasureValues` does in
[`Input_HysLaw()`](https://jwildfire.github.io/gsm.safety/dev/reference/Input_HysLaw.md).
A test name that no entry names resolves to `NA`.

## Usage

``` r
ResolveParameters(chrTest, lParameterValues)
```

## Arguments

- chrTest:

  `character` Test names, one per record.

- lParameterValues:

  Named `list` of `character`: names are reference parameters, values
  the data's test names.

## Value

`character` of `length(chrTest)`: the parameter, or `NA`.
