# The `Census` table: which metric each named figure reads, and where it sits

The labels are a contract (D0023.5, approved). The safety overview picks
`Enrolled participants`, `Received study drug`,
`Person-years on treatment` and `Deaths` out of this payload by exact
string and drops a tile silently if one is reworded, so the labels stay
word for word and a test says so.

## Usage

``` r
.CENSUS_LEGACY_FIGURES
```

## Format

An object of class `data.frame` with 10 rows and 4 columns.

## Details

`Denominator` is whether the figure is published beside one *here*.
Every metric publishes a denominator, and the report shows it in a
column headed with what it counts; this payload has no such column, and
its reader turns any denominator into a percentage. "73.2 person-years
of 762 (10%)" is what carrying it through would produce, so the figures
with no percentage to state carry no denominator, exactly as before.
