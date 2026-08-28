# Read a person-time column as days

A column that is not a number is an error, not a column of missing
values. A study whose `timeonstudy` arrived as free text has not
recorded zero days for everybody; it has recorded something this metric
cannot read, and silently reading it as missing is the defect shape this
rebuild removes.

## Usage

``` r
ParticipantDayValues(vDays, strDayCol, strDomainName = "dfSubjects")
```

## Arguments

- vDays:

  Vector to read as person-time in days.

- strDayCol:

  `character` Column name, for the message.

- strDomainName:

  `character` Domain name, for the message.

## Value

`numeric` of `length(vDays)`, missing where the study recorded nothing.
