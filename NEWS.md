<!--
NEWS.md is the running release log and the draft of each release's notes
(obot.agent/skills/rc-release-notes/SKILL.md): newest section first; unreleased
work accumulates under a vX.Y.Z (Upcoming) heading that loses the suffix when
the release is cut; the GitHub release publishes from the section verbatim.
-->

# gsm.safety v1.1.0 (Upcoming)

- **Two new widgets — `Widget_HepWaterfall()` and `Widget_NepExplorer()`** — the hepatic ALT waterfall for abnormal-baseline trials (Amirzadegan et al. 2025, Fig. 5) and the KDIGO nephrotoxicity explorer, each with its report workflow, example page, and bundled demo cohort (`adbds_abnbl`; synthetic `AKI-*` participants join `adbds`). ([obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164), [#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **The vendored safety.viz bundle moves from v1.4.0 to v1.6.0**, so every widget now renders with two releases of upstream fixes and features it was missing — including the corrected eDISH peak computation ([safety.viz#91](https://github.com/jwildfire/safety.viz/issues/91): the v1.4.0 bundle counted a participant's own baseline as an on-treatment peak when no day-0 record existed), participant-profile drill-down on six charts, the migration Sankey view, eDISH direct manipulation, study-day playback, and the shared hep/qt view selector. ([#49](https://github.com/jwildfire/gsm.safety/issues/49))
- **A safety.viz parity guard makes the next drift loud**: `DESCRIPTION` declares the wrapped library version (`Config/safetyviz/version`), an offline test keeps the declaration, the vendored bundle, and every widget binding in agreement, and a CI workflow checks the latest safety.viz release — blocking PRs on unwrapped renderers unless `.github/parity-allowlist.yaml` cites a filed requirement, and filing an adoption issue automatically on its weekly schedule. ([obot.roadmap#164](https://github.com/jwildfire/obot.roadmap/issues/164), [#49](https://github.com/jwildfire/gsm.safety/issues/49))

- **Report workflows reorganized into a `4_modules` phase, with a new `2_metrics` phase** — metric generation now runs as its own pipeline step ahead of module assembly, matching the gsm ecosystem's staged YAML workflow layout. ([#47](https://github.com/jwildfire/gsm.safety/pull/47))

# Earlier releases

- [v1.0.0](https://github.com/jwildfire/gsm.safety/releases/tag/v1.0.0) — 2026-07-23.
- [gsm.safety v0.1.0](https://github.com/jwildfire/gsm.safety/releases/tag/v0.1.0) — 2026-05-15.
