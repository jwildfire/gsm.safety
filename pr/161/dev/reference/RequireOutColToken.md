# Require that an output column name carries the token its siblings are derived from

[`Derive_AbnormalityLevel()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_AbnormalityLevel.md)
names its direction and criterion columns by replacing `Level` in
`strOutCol`;
[`Derive_ExtremeValueFlag()`](https://jwildfire.github.io/gsm.safety/dev/reference/Derive_ExtremeValueFlag.md)
replaces `Flag`. A name without the token would collapse the outputs
onto one column.

## Usage

``` r
RequireOutColToken(strOutCol, strToken)
```

## Arguments

- strOutCol:

  `character` The requested output column name.

- strToken:

  `character` The token it must contain.
