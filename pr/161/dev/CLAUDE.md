# gsm.safety

R bindings for the safety.viz chart library (thirteen `Widget_*`
htmlwidgets), participant-level safety metrics, the safety census, and
the FDA Standard Safety Tables and Figures static displays as they
arrive. Mirrors the gsm.kri / gsm.viz architecture. `dev` is the
integration branch (merges on green checks); `main` is the release
branch (@jwildfire’s review).

# Standards

The obot program’s standards are mandatory here: the issue contract,
ways of working and developer guidelines in jwildfire/obot.roadmap
`docs/` (on disk at ~/obot.roadmap/docs/ in a cloud environment). Work
runs one requirement per session
(`/requirement-session <hub requirement>`).

# Commands

- `devtools::document()` — regenerate `man/` and `NAMESPACE` after any
  roxygen change.
- `devtools::test()` — the testthat suite (edition 3). `pkgdown/` is
  `.Rbuildignore`d, so the example-page and gallery tests run here and
  skip under check.
- `devtools::check()` — must be clean (no errors, warnings or notes)
  before a PR opens; CI runs the same check through
  `gilead-public/gsm.utils`.
- `tools/check-safety-viz-parity.sh` — the cross-repo half of the parity
  guard: the vendored bundle must be the latest safety.viz release and
  every renderer it exports must have a `Widget_*.R` or a cited deferral
  in `.github/parity-allowlist.yaml`. The offline half is
  `tests/testthat/test-safety-viz-parity.R`.
- [`gsm.utils::build_assets()`](https://rdrr.io/pkg/gsm.utils/man/build_assets.html)
  — renders the `Example_*.Rmd` pages into `pkgdown/assets/examples/`
  for the site.

# Conventions

- Every `test_that()` name ends with the issue it proves, `(#N)`;
  `tests/testthat/test-qcthat-convention.R` fails the suite otherwise.
- Argument and variable prefixes follow gsm.core: `df` data frame, `l`
  list, `str` character scalar, `chr` character vector, `n` numeric, `b`
  logical.
- Widgets validate data and settings through
  [`BuildWidgetPayload()`](https://jwildfire.github.io/gsm.safety/dev/reference/BuildWidgetPayload.md)
  against the module’s vendored contract in `inst/schema/`; settings are
  overrides merged client-side, so pass only what differs from the
  defaults.
- Metric cut-points live in the workflow `meta` block under
  `inst/workflow/2_metrics/`, never in R.
- `NEWS.md` is always current on `dev`: unreleased work goes under the
  `vX.Y.Z (Upcoming)` heading as it lands, one user-facing bullet per
  feature linking its hub requirement and PR.
- A session waiting on @jwildfire (a blocked question, a release
  candidate awaiting his review) checks back every 12 hours, not hourly:
  one scheduled check-in at a time, re-armed silently when nothing
  changed, and the nightly comment on the requirement is the only
  routine write. PR events still wake the session immediately.
- One branch per task, `<task-number>-<slug>`, off `dev`; the PR body
  carries `Closes #<task>` and the definition-of-done evidence. Release
  candidates are `gsm.safety vX.Y.Z-RCn` from `dev` into `main`, drafted
  until ultrareview is clean, and never merged by an agent.
