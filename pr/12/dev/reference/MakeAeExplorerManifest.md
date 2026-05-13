# Create an AE Explorer report manifest

Create the first `workr`-compatible output for the AE Explorer report.
The function does not render the SafetyCharts widget yet; it records the
report inputs, mappings, and open data gaps that downstream rendering
work will use.

## Usage

``` r
MakeAeExplorerManifest(lData, lSettings, lMeta = list())
```

## Arguments

- lData:

  A named list of workflow data frames.

- lSettings:

  AE Explorer settings from
  [`MakeAeExplorerSettings()`](https://obot-claw.github.io/gsm.safety/dev/reference/MakeAeExplorerSettings.md).

- lMeta:

  Workflow metadata.

## Value

A manifest list describing the AE Explorer report configuration.
