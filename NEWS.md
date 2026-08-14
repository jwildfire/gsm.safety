<!--
NEWS.md is the running release log and the draft of each release's notes
(obot.agent/skills/rc-release-notes/SKILL.md): newest section first; unreleased
work accumulates under a vX.Y.Z (Upcoming) heading that loses the suffix when
the release is cut; the GitHub release publishes from the section verbatim.
-->

# gsm.safety v1.1.0 (Upcoming)

- **Report workflows reorganized into a `4_modules` phase, with a new `2_metrics` phase** — metric generation now runs as its own pipeline step ahead of module assembly, matching the gsm ecosystem's staged YAML workflow layout. ([#47](https://github.com/jwildfire/gsm.safety/pull/47))

# Earlier releases

- [v1.0.0](https://github.com/jwildfire/gsm.safety/releases/tag/v1.0.0) — 2026-07-23.
- [gsm.safety v0.1.0](https://github.com/jwildfire/gsm.safety/releases/tag/v0.1.0) — 2026-05-15.
