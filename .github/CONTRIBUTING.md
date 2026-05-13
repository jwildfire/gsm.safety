# Contributing to gsm.safety

This repository follows the `gsm` package development conventions where they are useful for an early-stage experimental package.

## Before opening a PR

- File or link an issue describing the intended change.
- Run the relevant local checks when possible.
- Keep workflow/report changes tied to the GitHub issue that motivates them.

## CI expectations

This repository uses GitHub Actions templates from `Gilead-BioStats/gsm.utils`:

- `R-CMD-check.yaml` — R CMD check on pull requests.
- `test-coverage.yaml` — test coverage reporting.
- `pkgdown-all.yaml` — pkgdown site build/deploy and PR previews.
- `r-releaser-caller.yaml` — release automation.
- `workflow-template-check.yaml` — checks workflow templates against `gsm.utils`.

The first automation PR intentionally ports the standard suite while documenting any repo-specific follow-up work in #8.
