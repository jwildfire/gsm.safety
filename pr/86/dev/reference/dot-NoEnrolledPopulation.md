# Is the enrolled population empty?

No denominator is not a denominator of zero. A study whose subject
domain has no rows has no population to count against, so nothing is
published.

## Usage

``` r
.NoEnrolledPopulation(dfSubjects)
```

## Arguments

- dfSubjects:

  `data.frame` Enrolled population.

## Value

`logical(1)`, with a warning logged when `TRUE`.
