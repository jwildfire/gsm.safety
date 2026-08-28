# Align a named per-participant vector to a participant ID vector

Align a named per-participant vector to a participant ID vector

## Usage

``` r
AlignToParticipants(vNamed, chrIDs)
```

## Arguments

- vNamed:

  Named `numeric` as returned by
  [`PeakByParticipant()`](https://jwildfire.github.io/gsm.safety/dev/reference/PeakByParticipant.md).

- chrIDs:

  `character` Participant IDs to align to.

## Value

`numeric` of `length(chrIDs)`, `NA` where the participant is absent.
