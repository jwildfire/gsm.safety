# Highest tier reached, given ordered tier conditions

Each element of `lConditions` is a logical vector over the same
participants, named by the tier it confers. The result is the maximum
tier whose condition holds, and `0` where none does.

## Usage

``` r
HighestTier(lConditions, nLength)
```

## Arguments

- lConditions:

  Named `list` of logical vectors; names are the tier numbers as
  character (`"1"`, `"2"`, `"3"`).

- nLength:

  `integer` Number of participants.

## Value

`numeric` tier per participant.
