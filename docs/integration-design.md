# `obot-claw/gsm.safety` integration design

_Date: 2026-05-09_

## Goal

Design a future R package, `gsm.safety`, that makes the SafetyGraphics chart ecosystem available inside Good Statistical Monitoring (`gsm.core`) pipelines. The package should let a GSM workflow produce reusable, inspectable safety visuals from `Mapped_*`, `Analysis_*`, and `Reporting_*` data without forcing users to launch the full SafetyGraphics Shiny app.

The recommended initial direction is **a lightweight GSM module package**: wrap SafetyGraphics/safetyCharts chart configuration, metadata, mapping, and rendering into `gsm.core::RunWorkflow()`-compatible YAML modules. Avoid deep rewrites of either ecosystem.

## Evidence base

Key upstream facts used in this design:

- `safetyGraphics` provides a framework and Shiny app for clinical trial safety graphics, built around a flexible data pipeline and shareable chart exports/reports: <https://safetygraphics.github.io/safetyGraphics/>.
- SafetyGraphics charts can be static plots, Shiny modules, htmlwidgets, HTML, tables, or RTF-like static outputs. Several default charts live in `safetyCharts`, not `safetyGraphics`: <https://safetygraphics.github.io/safetyGraphics/articles/ChartConfiguration.html>.
- `safetyGraphicsApp()` accepts `domainData`, `mapping`, `charts`, and `meta`; the cookbook treats `domainData` and `mapping` as study-specific and `charts`/`meta` as reusable: <https://safetygraphics.github.io/safetyGraphics/articles/Cookbook.html>.
- SafetyGraphics default domains include `labs`, `aes`, and `dm`; default minimum data requirements are documented in the intro vignette: <https://safetygraphics.github.io/safetyGraphics/articles/Intro.html>.
- `makeChartConfig()` reads chart YAML from packages/directories and binds workflow functions; `prepareChart()` sets defaults and binds functions: <https://safetygraphics.github.io/safetyGraphics/reference/makeChartConfig.html>, <https://safetygraphics.github.io/safetyGraphics/reference/prepareChart.html>.
- `makeMapping()` builds app mapping from `domainData`, metadata, auto-detected standards, and custom mapping: <https://safetygraphics.github.io/safetyGraphics/reference/makeMapping.html>.
- `gsm.core` is the analytics foundation of the modular GSM suite; it runs standardized workflows and separates mapping, metrics, reporting, and modules: <https://gilead-biostats.github.io/gsm.core/>.
- GSM data flows from raw data to mapped data to analysis data to reporting data. `RunWorkflow()` executes YAML-defined steps over `lData`/`lMeta`; `RunStep()` parses scalar string params from `lMeta` or `lData`: <https://gilead-biostats.github.io/gsm.core/articles/DataModel.html>, <https://gilead-biostats.github.io/gsm.core/reference/RunWorkflow.html>, <https://gilead-biostats.github.io/gsm.core/reference/RunStep.html>.
- GSM extensions are expected to be R packages with YAML files under `inst/workflow/4_modules`; each module YAML has `meta`, `spec`, and `steps`: <https://gilead-biostats.github.io/gsm.core/articles/gsmExtensions.html>.

Local cloned repo references checked under `research/gsm-safety/repos/`:

- `safetyCharts/inst/config/aeExplorer.yaml` and `safetyOutlierExplorer.yaml` show current chart config structure (`domain`, `dataSpec`, `workflow$init`, `workflow$widget`).
- `gsm.kri/inst/workflow/2_metrics/kri0001.yaml` shows a canonical analysis workflow and final `lAnalysis` output.
- `gsm.kri/inst/workflow/4_modules/report_kri_site.yaml` shows a canonical report module using `Reporting_*` inputs and `gsm.kri::MakeCharts()`/`Report_KRI()`.

## Design principles

1. **Bridge, do not fork.** Treat `safetyGraphics` and `safetyCharts` as chart engines/config providers; treat `gsm.core` as orchestration and data-contract enforcement.
2. **Prefer GSM workflow modules over a monolithic app.** `gsm.safety` should run in scripted/qualified pipelines via `RunWorkflow()` and optionally expose an interactive app later.
3. **Make data contracts explicit.** SafetyGraphics mappings are flexible; GSM specs are rigid. The package should translate between them with validated adapters.
4. **Keep charts independently reproducible.** Outputs should include chart object/config, input data snapshot or digest, mapping, and package versions.
5. **Support progressive adoption.** Start with existing `Mapped_*` data and a small chart subset; do not require all GSM reporting tables on day one.

## Proposed package architecture

```text
gsm.safety/
  R/
    sg-chart-config.R        # load/filter/prepare SafetyGraphics chart configs
    sg-data-contract.R       # map GSM data layers to SafetyGraphics domainData
    sg-mapping.R             # generate/validate SafetyGraphics mapping lists
    sg-render.R              # render static/htmlwidget/chart bundles
    sg-module.R              # workflow-facing functions called from YAML
    sg-report.R              # optional report assembly helpers
    validators.R             # assert_* functions and typed errors
  inst/
    workflow/
      4_modules/
        safety_labs_outliers.yaml
        safety_ae_explorer.yaml
        safety_bundle.yaml
    config/
      chart-allowlist.yaml   # optional curated chart set/version pins
  tests/
    testthat/
  vignettes/
    gsm-safety-minimal.Rmd
    data-contracts.Rmd
```

### Dependency stance

- `Imports`: `gsm.core`, `safetyGraphics`, `dplyr`, `purrr`, `rlang`, `yaml`, `htmltools`, `htmlwidgets`, `jsonlite`, `tibble`.
- `Suggests`: `safetyCharts`, `safetyData`, `gsm.kri`, `gsm.reporting`, `testthat`, `vdiffr`, `shinytest2` or `shinytest`, `rmarkdown`, `withr`.
- Recommendation: put `safetyCharts` in `Suggests` until the MVP proves whether default chart configs are mandatory. Functions should error clearly if requested charts require missing packages.

## Core API proposal

### 1. Load chart definitions

```r
sg_chart_config <- function(
  charts = NULL,
  packages = "safetyCharts",
  dirs = NULL,
  domains = NULL,
  types = c("plot", "plotly", "htmlwidget", "table", "html"),
  include_modules = FALSE
)
```

Wrapper around `safetyGraphics::makeChartConfig()` plus filtering. Defaults should exclude Shiny modules from automated GSM reports because module export/reproducibility is harder than static/htmlwidget outputs.

Returns a named list of prepared SafetyGraphics chart objects.

### 2. Convert GSM data to SafetyGraphics `domainData`

```r
sg_domain_data <- function(
  lData,
  domains = c("dm", "aes", "labs"),
  source = c("mapped", "raw", "reporting"),
  table_map = sg_default_table_map(),
  derive = TRUE
)
```

Default table mapping:

| SafetyGraphics domain | Preferred GSM source | Notes |
|---|---|---|
| `dm` | `Mapped_SUBJ` | Subject-level demographics/enrollment. Must include subject ID; optional sex, race, age, treatment. |
| `aes` | `Mapped_AE` | AE-level data. Must include subject ID; preferred term/body system/start/end/severity if available. |
| `labs` | `Mapped_LB` or package-specific lab mapping | Lab-level data. Not always present in core KRI pipelines; may require new mapping workflow. |
| `kri_results` (new/custom) | `Reporting_Results` | For GSM-specific charts, not existing SafetyGraphics defaults. |
| `kri_groups` (new/custom) | `Reporting_Groups` | Group metadata, useful for drilldowns. |
| `kri_metrics` (new/custom) | `Reporting_Metrics` | Metric labels/models/score metadata. |

This function should not silently invent variables. If a SafetyGraphics chart requires a field that does not exist, return an actionable validation error showing the missing domain, field, expected source, and candidate columns.

### 3. Build SafetyGraphics mapping from GSM metadata

```r
sg_mapping <- function(
  domainData,
  charts,
  meta = NULL,
  customMapping = NULL,
  autoMapping = TRUE,
  standard = c("auto", "sdtm", "adam", "gsm")
)
```

Internally delegates to `safetyGraphics::makeMapping()` where possible. Add a `gsm` mapping profile for `Mapped_*` tables, e.g. `subjid -> id_col`, `invid -> site_col` when relevant.

### 4. Render one chart or a bundle

```r
sg_render_chart <- function(
  chart,
  domainData,
  mapping,
  output_dir = tempdir(),
  output_format = c("object", "html", "png", "rds"),
  include_export_code = TRUE
)

sg_render_bundle <- function(
  charts,
  domainData,
  mapping,
  output_dir,
  index = TRUE
)
```

Return an object with:

```r
list(
  chart_id = "safetyOutlierExplorer",
  chart_type = "htmlwidget",
  path = ".../safetyOutlierExplorer.html",
  object = <optional chart object>,
  mapping = <mapping used>,
  data_digest = <hashes/row counts>,
  messages = <validation/render notes>
)
```

For htmlwidgets, use `htmlwidgets::saveWidget()`; for ggplot/plotly use appropriate save paths; for plain objects allow `rds` output.

### 5. Workflow-facing module function

```r
RunSafetyGraphics <- function(
  lData,
  lMeta = NULL,
  charts = NULL,
  domains = NULL,
  output_dir = "safetygraphics",
  customMapping = NULL,
  chart_types = c("plot", "plotly", "htmlwidget", "table", "html"),
  return = c("manifest", "objects", "paths")
)
```

This is the primary function called by GSM YAML modules. It returns a manifest data frame/list suitable for downstream reports.

Example module YAML:

```yaml
meta:
  Type: App
  ID: safety_labs_outliers
  Output: html
  Name: SafetyGraphics Lab Outlier Bundle
  Description: SafetyGraphics lab outlier charts generated from GSM mapped lab data
  Status: Prototype
spec:
  Mapped_SUBJ:
    subjid:
      type: character
  Mapped_LB:
    subjid:
      type: character
steps:
  - output: SafetyGraphics_Manifest
    name: gsm.safety::RunSafetyGraphics
    params:
      lData: lData
      charts: safetyOutlierExplorer
      domains: labs
      output_dir: safetygraphics/labs
```

Important implementation note: because `gsm.core::RunStep()` can pass the full `lData` when a param value equals `lData`, `RunSafetyGraphics(lData = lData, ...)` fits the current workflow parser.

## Data contract mapping

### SafetyGraphics contract

SafetyGraphics is chart-first and mapping-driven:

- `domainData`: named list of data frames, with names matching chart domains.
- `mapping`: nested list keyed by domain and SafetyGraphics metadata keys such as `id_col`, `value_col`, `measure_col`.
- `meta`: table defining available fields/columns and standard names.
- `charts`: list of chart configs with `domain`, `dataSpec`, and `workflow`.

Default domain expectations from SafetyGraphics docs:

- `labs`: one record per person/visit/lab measurement; participant ID, lab result, lab name, normal limits, study day, visit numeric/character.
- `aes`: one record per AE; participant ID, AE sequence, study day, AE start/end, preferred term, body system.
- `dm`: one record per person; participant ID, sex, race, age, optional treatment.

### GSM contract

GSM is workflow/data-layer driven:

- `Mapped_*`: standardized-ish input for analytics; no universal mapped standard, but each workflow YAML `spec` declares required columns.
- `Analysis_*`: KRI pipeline objects (`Analysis_Input`, `Analysis_Transformed`, `Analysis_Analyzed`, `Analysis_Flagged`, `Analysis_Summary`).
- `Reporting_*`: standardized reporting layer (`Reporting_Results`, `Reporting_Bounds`, `Reporting_Groups`, `Reporting_Metrics`).

For existing KRI workflows, `Mapped_AE` and `Mapped_SUBJ` often have lower-case fields such as `subjid`, `invid`, and `timeonstudy`; see the AE KRI `kri0001.yaml` pattern.

### Adapter strategy

Use explicit adapter objects instead of relying only on automatic detection:

```r
sg_default_table_map <- function() {
  list(
    dm = list(table = "Mapped_SUBJ", mapping = list(id_col = "subjid")),
    aes = list(table = "Mapped_AE", mapping = list(id_col = "subjid")),
    labs = list(table = "Mapped_LB", mapping = list(id_col = "subjid"))
  )
}
```

Then layer project-specific custom mappings over these defaults. The adapter should support both:

1. **Pass-through mode**: use current `Mapped_*` column names directly and tell SafetyGraphics which columns to use.
2. **Rename/derive mode**: create SafetyGraphics-friendly domain data with conventional names, retaining source metadata.

Recommendation for MVP: implement pass-through mode first; add derive/rename helpers only for known gaps.

## Minimal viable slice

### MVP 0: proof of concept

One workflow module that generates one or two SafetyGraphics charts from a GSM `lData` object.

Scope:

- Chart: `safetyCharts::safetyOutlierExplorer` or static outlier explorer if lab mapped data is available; otherwise `aeExplorer` because AE/SUBJ are already central to GSM KRI examples.
- Input: `Mapped_SUBJ` + `Mapped_AE` for AE, or `Mapped_SUBJ` + `Mapped_LB` for labs.
- Output: HTML widget file(s) plus a manifest object.
- No Shiny module charts.
- No full `safetyGraphicsApp()` launch inside GSM workflow.

Deliverables:

- `RunSafetyGraphics()`
- `sg_domain_data()`
- `sg_mapping()`
- `sg_render_chart()`
- `inst/workflow/4_modules/safety_ae_explorer.yaml`
- One vignette using sample `gsm.core`/`gsm.kri` data and `gsm.core::RunWorkflow()`.

### MVP 1: useful reporting add-on

- Generate a chart bundle for `aes`, `dm`, and `labs` where available.
- Add an `index.html` for the bundle.
- Provide a GSM report module that can link the bundle from a KRI report or return a manifest that `gsm.reporting`/`gsm.kri` can consume.
- Add validation reports that enumerate which SafetyGraphics charts were skipped and why.

### MVP 2: GSM-native SafetyGraphics charts

Create new SafetyGraphics-compatible chart configs for GSM reporting data:

- Risk/flag scatter by `Reporting_Results` + `Reporting_Bounds`.
- Group drilldown using `Reporting_Groups`.
- Longitudinal flag changes if historical `Reporting_Results` are present.

These should use a new custom SafetyGraphics domain such as `kri_results`, demonstrating the documented SafetyGraphics pattern for adding new domains.

## Testing and qualification strategy

### Unit tests

- `sg_domain_data()` maps expected `Mapped_*` tables to expected SafetyGraphics domains.
- `sg_mapping()` returns expected nested mapping and respects custom overrides.
- Validators catch missing tables/columns/types with stable error classes.
- `sg_chart_config()` filters chart types/domains correctly and errors clearly on missing packages.
- `RunSafetyGraphics()` works when called directly and through `gsm.core::RunWorkflow()`.

### Golden/object tests

- Store small fixture `lData` lists with `Mapped_SUBJ`, `Mapped_AE`, and optionally `Mapped_LB`.
- Snapshot the manifest structure, row counts, chart IDs, and validation messages.
- For static ggplot outputs, use `vdiffr` cautiously. For htmlwidgets, prefer DOM/file existence and JSON payload sanity checks over brittle pixel snapshots.

### Integration tests

- Run a minimal GSM mapping + KRI + safety module workflow from YAML.
- Verify `gsm.core::RunWorkflow()`/`RunWorkflows()` can pass `lData` into `RunSafetyGraphics()` and receive a manifest.
- Test absence/presence of optional chart packages.

### Shiny/module tests

Defer Shiny module chart support. When added, use `shinytest2` or `shinytest`, but keep it outside the core MVP because module rendering is not the same as report artifact generation.

### Qualification alignment

If `gsm.safety` is intended for GCP/RBQM use, align with the GSM QC posture documented by `gsm.core`: requirements linked to tests, package checks in CI, qualification reports, and environment traceability. Start by giving each module and function requirement IDs that can later map to `qcthat` or the relevant GSM QC process.

## Open questions for Jeremy / maintainers

1. Should `gsm.safety` live under `obot-claw`, `Gilead-BioStats`, or `SafetyGraphics` long term?
2. Is the primary deliverable a **report artifact** generated in GSM workflows, or an **interactive app** launched from GSM data snapshots?
3. Which source data standard should MVP target: GSM `Mapped_*`, SDTM/ADaM raw domains, or `Reporting_*` outputs?
4. Is lab data (`Mapped_LB`) available in the intended first GSM pipelines, or should the first chart be AE-based?
5. Should existing `safetyCharts` be a hard dependency, or should `gsm.safety` ship curated chart wrappers/configs to reduce dependency surface?
6. How much provenance is required for chart outputs: full data snapshot, hashes only, or reproducible code bundle?
7. Should generated SafetyGraphics charts be embedded into existing `gsm.kri::Report_KRI()` reports, linked as external HTML, or emitted as separate module outputs?
8. Are Shiny module charts required, or can the first qualified scope exclude them?

## Recommendation

Build `gsm.safety` as a **GSM extension/module package** with a small number of workflow-facing functions. The first milestone should be an AE or lab SafetyGraphics htmlwidget bundle generated from `Mapped_*` data through `gsm.core::RunWorkflow()`, returning a manifest that downstream GSM reports can link or embed.

This path keeps both ecosystems intact, makes validation feasible, and creates an incremental bridge: first existing SafetyGraphics charts from GSM mapped data, then GSM-native chart domains over `Reporting_*` data.
