# CI automation

Issue #8 tracks adding the fuller GitHub Actions automation suite used by `gsm.utils`.

## Source

The workflow files in `.github/workflows/` are based on the canonical `gsm.utils` action templates from the `actions-v1` branch:

- `R-CMD-check.yaml`
- `pkgdown-all.yaml`
- `r-releaser-caller.yaml`
- `test-coverage.yaml`
- `workflow-template-check.yaml`

Issue templates are adapted from `gsm.utils` `inst/gha_templates/ISSUE_TEMPLATE`. The Gilead roadmap project binding was removed because this repo lives under `obot-claw`.

## Follow-up notes

- The workflows rely on reusable actions/workflows from `Gilead-BioStats/gsm.utils@actions-v1`.
- `pkgdown-all.yaml` assumes GitHub Pages can be enabled for the repository when site deployment is desired.
- Release automation is present but only runs on GitHub releases or manual dispatch.
- Workflow compliance intentionally checks against the upstream `gsm.utils` templates so drift is visible.
