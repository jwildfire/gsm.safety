# gsm.safety

`gsm.safety` is an early-stage R package concept for bringing clinical safety visualizations inspired by the SafetyGraphics ecosystem into Good Statistical Monitoring (`gsm.core`) workflows.

Initial direction: build a lightweight GSM extension/plugin package that bridges GSM `lData` objects and mapped domains (`Mapped_SUBJ`, `Mapped_AE`, `Mapped_LB`, etc.) to selected SafetyGraphics-style chart artifacts. Avoid forking the full `safetyGraphics` Shiny app; start with workflow-generated report artifacts and optional `gsm.app` plugins later.

## Current status

This repository is a newly scaffolded prototype package. It currently contains:

- [Integration design](docs/integration-design.md)
- Minimal package metadata in `DESCRIPTION`
- A `testthat` harness for early package checks
- GitHub Actions R CMD check for pull requests and pushes to `main`

The package API is not implemented yet; the first development milestone is to define the GSM-to-SafetyGraphics data contract.

## Development

This project intentionally does **not** use `renv` yet. The dependency surface is still changing, and the MVP should first establish the core package/API boundaries before adding lockfile maintenance.

Run local checks with:

```r
rcmdcheck::rcmdcheck(args = "--no-manual")
```

or from a shell with R installed:

```sh
R CMD check --no-manual gsm.safety
```

## Proposed MVP

1. Define a minimal package skeleton.
2. Implement data-contract adapters from GSM mapped data to SafetyGraphics-style `domainData`.
3. Render one AE-focused chart artifact from `Mapped_SUBJ` + `Mapped_AE` through a `gsm.core` workflow module.
4. Add validation, tests, and a small reproducible fixture.

## License

Apache License 2.0.
