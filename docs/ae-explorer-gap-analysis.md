# AE Explorer gap analysis

Issue #10 makes AE Explorer the first concrete `gsm.safety` report. This note
starts the implementation by comparing the chart inputs required by the
SafetyCharts AE Explorer wrapper and the RhoInc `aeexplorer` widget with the
current `gsm.mapping` workflow outputs.

## Target report

- SafetyCharts wrapper: `safetyCharts::aeExplorer()` / `init_aeExplorer()`
- RhoInc widget: `aeexplorer`
- Planned `gsm.safety` report id: `ae_explorer`

## Minimum inputs from SafetyCharts

The SafetyCharts wrapper expects two domains:

- `dm` participant-level data
- `aes` adverse-event-level data

The wrapper's chart config identifies these required mappings:

| SafetyCharts domain | Mapping key | Meaning | Candidate `gsm.mapping` source |
| --- | --- | --- | --- |
| `dm` | `id_col` | subject identifier | `Mapped_SUBJ$subjid` |
| `dm` | `treatment_col` | treatment/group column | open gap |
| `aes` | `id_col` | subject identifier | `Mapped_AE$subjid` |
| `aes` | `term_col` | preferred term | `Mapped_AE$mdrpt_nsv` |
| `aes` | `bodsys_col` | body system / SOC | `Mapped_AE$mdrsoc_nsv` |

## Useful RhoInc AE Explorer fields

The underlying RhoInc widget defaults to ADaM/SDTM-style names including
`USUBJID`, `ARM`, `AEBODSYS`, `AEDECOD`, `AESER`, `AESEV`, `AEREL`, and `AEOUT`.
The SafetyCharts wrapper only requires the id, group, body-system, and term
mappings, but the optional filters are important for a useful first report.

| Widget concept | Default widget field | Candidate `gsm.mapping` source | Status |
| --- | --- | --- | --- |
| Seriousness | `AESER` | `Mapped_AE$aeser` | available |
| Severity | `AESEV` | `Mapped_AE$aetoxgr` | candidate; confirm semantics |
| Relationship | `AEREL` | `Mapped_AE$aerel` | available |
| Outcome | `AEOUT` | none identified | gap |

## Initial gaps

1. **Treatment/grouping**: `Mapped_SUBJ` does not currently expose an obvious
   treatment arm or group field for `dm$treatment_col`. `Mapped_Randomization`
   has randomization status/date metadata but not treatment arm in the inspected
   mapping YAML.
2. **AE outcome**: no current `Mapped_AE` field clearly maps to the widget's
   `AEOUT` default.
3. **Severity semantics**: `aetoxgr` may be sufficient for a severity filter,
   but this should be documented as toxicity grade rather than silently treated
   as a verbatim `AESEV` equivalent.

## Recommendation for the first implementation slice

- Add an AE Explorer report YAML scaffold that declares the known direct
  mappings and records the open gaps.
- Allow the first report to run without treatment grouping by using an explicit
  placeholder group, matching the SafetyCharts wrapper behavior when no
  treatment column is provided.
- Do not invent treatment arm or AE outcome derivations in `gsm.safety` until the
  source mapping strategy is agreed.
