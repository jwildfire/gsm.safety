# ADaM to Mapped_* alignment for the FDA ST&F domains

The FDA Standard Safety Tables and Figures guide is written against ADaM. gsm.safety holds two other shapes: the vendored example data behind `ExampleData()` and the `Mapped_*` domains gsm.mapping produces from raw EDC. Before the phase 1 engines are coded, this note checks, column by column, what the 22 figures and the phase 0 derivations need from ADSL, ADAE, ADLB and ADVS, where each column already lives, and what to do about every gap. It settles the open data question in the jwildfire/obot.roadmap#9 design and ends with the column contract the engines code against. Task: jwildfire/gsm.safety#80. Date: 2026-09-11.

## Sources

- The figure inventory, `reports/fda-stf-static-displays-plan-2026-07-21/fda_stf_inventory.json` in jwildfire/obot.roadmap: 22 figures with their domains, the eight chart engines they collapse to, and the cross-cutting rules.
- The guide, FDA CDER Standard Safety Tables and Figures Integrated Guide v2.0 (April 2025). Sections are cited by number below.
- The vendored example data, read with `gsm.safety::ExampleData()` over `inst/extdata/adsl.csv.gz`, `adae.csv.gz`, `adbds.csv.gz`, `adeg.csv.gz` (loader in `R/ExampleData.R`). Every count in this note comes from running that loader on 2026-09-11.
- gsm.mapping's standard mappings, `inst/workflow/1_mappings/SUBJ.yaml`, `AE.yaml`, `LB.yaml`, `VS.yaml`, `STUDCOMP.yaml`, `SDRGCOMP.yaml`, `Death.yaml`, `Randomization.yaml`, `ENROLL.yaml`, `VISIT.yaml`, and `R/complete_death.R`.
- gsm.core's `lSource` example (`data/lSource.rda`), whose `Raw_LB` carries the columns a standard lab source supplies.
- gsm.safety's own declared columns: `inst/workflow/2_metrics/saf0001.yaml` (`Mapped_LB`), `saf0003.yaml` (`Mapped_AE`), `saf0004.yaml` (`Mapped_Death`), `saf0007.yaml` to `saf0009.yaml` (`Mapped_SUBJ`), `saf0014.yaml` (`Mapped_STUDCOMP`), `R/SafetyCensus.R`, and the coverage comment in `inst/workflow/4_modules/safety_census.yaml`.
- `design/ae-explorer-gap-analysis.md`, which already recorded that no `Mapped_*` domain carries a treatment arm.
- The phase 0 datasets on gsm.safety#77 as specified there: `FDA_AbnormalityLevels` (Basis values absolute, uln_multiple, baseline_multiple, baseline_percent_decrease, baseline_change) and `FDA_ExtremeValues` (one row per parameter per UnitSystem, columns Unit, Low, High), and the derivations `Derive_ULNMultiple()`, `Derive_AbnormalityLevel()`, `Derive_ExtremeValueFlag()` that run over adbds-shaped long results. The branch had not been committed when this note was written, so its shapes are cited from the requirement, not from files.
- pharmaverseadam 1.3.0 from CRAN, installed into a scratch library on 2026-09-11 to test the vendoring decisions. Its `adsl`, `adae`, `adlb` and `advs` derive from the same CDISC pilot SDTM as the vendored example data. All 254 `adsl` subjects join to it on `USUBJID`, and our `adsl$ARM` equals its `TRT01A` for every subject.

## How to read the four states

Each needed column gets exactly one state, judged on the vendored example data first because that is what the demo pages render from. The `Mapped_*` column of every row is filled in regardless, so the gsm.mapping path can be read off the same table.

- `found`: in the vendored example data. The row names the dataset and column.
- `mapped`: not in the example data, but in a gsm.core or gsm.mapping `Mapped_*` domain. The row names domain and column.
- `derived`: in neither, but computable from columns that are. The row says from what.
- `missing`: in neither and not computable. The row carries the decision: vendor it from pharmaverseadam naming the ADaM variable, derive it once a prerequisite is vendored, or declare the figure out of scope on the demo data.

No `blocked` questions were needed. Every gap has a decision with its rationale.

Figures are grouped by engine, following the inventory's rollup: KM (F1, F4, F11, F13, F14), dual dot-forest (F2, F3), box plot over time (F10, F16 to F20), mean change with CI (F6, F9), DILI quadrant scatter (F7, F8), shift scatter (F15, F22), paired bars (F5, F21), point-range (F12).

## What the example data holds

`adsl` has 254 rows and four columns: `USUBJID`, `ARM`, `EOSDY`, `EOSSTT`. `adae` has 1159 rows: `USUBJID`, `ARM`, `AESEQ`, `AEBODSYS`, `AEDECOD`, `AETERM`, `AESEV`, `AESER`, `ASTDY`, `AENDY`. `adbds` has 57929 rows: `USUBJID`, `SITE`, `SITEID`, `SEX`, `RACE`, `ARM`, `VISIT`, `VISITNUM`, `TEST`, `STRESU`, `STRESN`, `STNRLO`, `STNRHI`. `adeg` has 5361 rows and adds `AGE`, `PARAMCD`, `BASE`, `CHG`, `ABLFL` to the same shape.

Three facts shape the tables below. First, `adbds` holds labs and vital signs in one long frame: 23 lab tests plus Systolic Blood Pressure, Diastolic Blood Pressure, Pulse Rate, Temperature and Weight. ADVS therefore maps onto `adbds` rows, not `adeg`. Second, `adbds` has 364 subjects but `adsl` has 254. The extra 110 are the synthetic AKI and CLD cohorts (sites "Nephrology Research Unit" and "Hepatology Research Unit") that exist for the hepatic and renal widgets. Third, `adbds` carries no dates and no study day anywhere, and its `VISITNUM` uses two schemes: lab rows number Week 2 as 4 and Week 12 as 9, vital-sign rows number Week 2 as 2 and Week 12 as 12.

## ADSL

| ADaM variable | Needed by | Example data | Mapped_* | State | Decision |
| --- | --- | --- | --- | --- | --- |
| `USUBJID` | every figure | `adsl$USUBJID`; also on `adae`, `adbds`, `adeg` | `Mapped_SUBJ$subjid` (SUBJ.yaml) | found | Key of every join. Contract name `USUBJID`; the `Mapped_*` path keeps `subjid`, which every `Input_*` step already defaults to. |
| `TRT01A` (actual arm) | every figure; risk difference in F2, F3; the arm panels of every plot | `adsl$ARM`, also carried on `adae`, `adbds`, `adeg`. It equals pharmaverseadam `TRT01A` for all 254 subjects and differs from planned `ARM` for 12, so it is the actual arm. | none. SUBJ.yaml and Randomization.yaml carry no arm; `design/ae-explorer-gap-analysis.md` recorded the same gap. | found | Engines take an arm column argument with default `ARM`. When the column is absent, as it is on every `Mapped_*` domain, the engine renders one arm and omits the risk-difference panel, the same fallback the AE Explorer note chose. gsm.safety does not derive an arm. |
| `SAFFL` | population rule for every AE, lab and VS display (guide 1.2, 2.1.1: at least one dose) | not in `adsl`. pharmaverseadam `adsl$SAFFL` is Y for all 254. | `Mapped_SUBJ$firstdosedate` not missing (SUBJ.yaml; saf0007.yaml counts on it) | derived | Safety population is subjects with a first dose date. On the demo data every `adsl` row qualifies, verified against pharmaverseadam. Vendor `SAFFL` when `adsl` is refreshed so the footnote can cite a flag. |
| `TRTSDT`, `TRTEDT`, `TRTDURD` | F1 (first dose to last dose, guide 2.1.7 note), the Duration footnote on every display, F12 person-years, on-treatment windows | not in `adsl`. pharmaverseadam `adsl` has all three for the 254 subjects (2 missing `TRTDURD`). | `Mapped_SUBJ$firstdosedate`, `Mapped_SUBJ$timeontreatment` (SUBJ.yaml; saf0009.yaml) | mapped | Vendor `TRTSDT`, `TRTEDT`, `TRTDURD` from pharmaverseadam `adsl`, joined on `USUBJID`, into `inst/extdata/adsl.csv.gz`. Until then F1 on the demo data uses `EOSDY` with `EOSSTT`, which guide 2.1.7 Customization allows as time to discontinuation from the trial, and the footnote says so. |
| `EOSDY`, `EOSSTT` | F1 interim event, F13 last follow-up, the remaining-in-trial bar height in F5 and F21 | `adsl$EOSDY` (1 to 213), `adsl$EOSSTT` (COMPLETED 110, DISCONTINUED 144) | `Mapped_STUDCOMP$compyn`, `compreas` (STUDCOMP.yaml; saf0014.yaml); day from `Mapped_SUBJ$timeonstudy` | found | Use as found. F13's event day is the last record day (guide 3.1.1 note); derive it as the larger of `EOSDY` and the last `ADY` across domains once `ADY` exists. |
| End-of-treatment status | F1 event indicator (discontinued treatment versus completed) | not in `adsl`; `EOSSTT` is trial disposition | `Mapped_SDRGCOMP$sdrgyn`, `sdrgreas` (SDRGCOMP.yaml) | mapped | Derive the F1 event as `TRTEDT` before the planned end of treatment once `TRTEDT` is vendored. On `Mapped_*` the event is `sdrgyn` not Y. |
| `DTHFL`, `DTHDT` | KM censoring, F14's example (AEs leading to death), the Deaths displays | not in `adsl`; `adae` has no outcome column. pharmaverseadam `adsl` has `DTHFL` (3 Y) and `DTHDT`. | `Mapped_Death$death_dt`, `death_dy` (Death.yaml; `complete_death()` adds `death_dy` from `rgmn_dt`; saf0004.yaml) | mapped | Vendor `DTHFL` and `DTHDT` from pharmaverseadam `adsl` into `adsl.csv.gz`. |
| `SEX` | sex-specific rows of Table 56 (HDL) and Table 57 (hemoglobin); sex-specific OCMQ denominators | not in `adsl`; `adbds$SEX` and `adeg$SEX`, constant within subject (verified) | `Mapped_SUBJ$sex` (SUBJ.yaml) | found | Engines read sex from the long domain when it carries one, else join it from ADSL. Vendor `SEX` into `adsl` on refresh. |
| `AGE` | subgroup tables only; no figure needs it | `adeg$AGE` only | `Mapped_SUBJ$agerep` (SUBJ.yaml) | found | Vendor `AGE` into `adsl` on refresh for the subgroup tables. Not a phase 1 input. |

## ADAE

| ADaM variable | Needed by | Example data | Mapped_* | State | Decision |
| --- | --- | --- | --- | --- | --- |
| `USUBJID` | F2, F3, F4, F11, F12, F14 | `adae$USUBJID` (254 subjects) | `Mapped_AE$subjid` (AE.yaml) | found | Key. |
| `TRT01A` | same | `adae$ARM`; all values present in `adsl$ARM` | none | found | As the ADSL row. Engines prefer the arm on ADSL and fall back to the one on the event frame. |
| `AEBODSYS` | F2 grouping | `adae$AEBODSYS` | `Mapped_AE$mdrsoc_nsv` (AE.yaml) | found | Use as found. |
| `AEDECOD` | F3 term membership; selecting the AE of interest for F4, F11, F14 | `adae$AEDECOD` | `Mapped_AE$mdrpt_nsv` (AE.yaml) | found | Use as found. |
| `AESER` | F4's example (SAEs); F14 for SAEs | `adae$AESER` (Y 3, N 1119, blank 37) | `Mapped_AE$aeser` (AE.yaml; saf0003.yaml) | found | Use as found. With 3 serious events the demo fails the guide's N of 8 per arm rule for an informative KM (2.2.5.2), so the demo F4 is drawn for a common preferred term and says so. |
| `AESEV` | severity filters in the overview tables; no figure input | `adae$AESEV` | `Mapped_AE$aetoxgr` (AE.yaml) is a toxicity grade, not a severity, as the AE Explorer note recorded | found | Use as found on the demo. On `Mapped_*` label it as grade. |
| `ASTDY` | event time for F4, F11, F14 (earliest AE start day); the interval axis of F12; the TEAE derivation | `adae$ASTDY` (37 missing) | derive from `Mapped_AE$aest_dt` minus `Mapped_SUBJ$firstdosedate` plus one (AE.yaml, SUBJ.yaml) | found | Use as found. Rows with a missing start day cannot enter a KM and are counted in the footnote. |
| `AENDY` | duration only; no figure input | `adae$AENDY` | derive from `Mapped_AE$aeen_dt` | found | Use as found. |
| `TRTEMFL` | the TEAE note on every AE display; the row filter of F2, F3, F12 | not in `adae`. pharmaverseadam `adae$TRTEMFL` is Y for 1122 of 1191 rows and missing for the rest. | none in AE.yaml | derived | Derive `TRTEMFL` as `ASTDY` at or above 1, the guide's definition (glossary 1.2: during or after the first treatment). Rows with a missing `ASTDY` keep a missing flag, matching pharmaverseadam. Vendor `TRTEMFL` on refresh as a cross-check. |
| `AEACN` | AEs leading to treatment discontinuation (tables and listings); no figure | not in `adae`; pharmaverseadam `adae$AEACN` is missing for every pilot row | none | missing | Out of scope on the demo data. The source study never recorded action taken, so nothing can be vendored or derived. The engines do not need it. |
| `AEOUT`, `AESDTH` | F14's example event (AEs leading to death) | not in `adae`; pharmaverseadam `adae` has `AEOUT` (FATAL 3) and `AESDTH` | none; the AE Explorer note recorded the `AEOUT` gap | missing | Vendor `AEOUT` and `AESDTH` from pharmaverseadam `adae`, joining on `USUBJID` and `AESEQ`, and check the row match at vendoring time (our 1159 rows against its 1191). Until then the demo F14 uses a chosen preferred term, which guide 4.1.1.1 Customization allows. |
| `AEREL` | related-event filters; no figure input | not in `adae` | `Mapped_AE$aerel` (AE.yaml; saf0003.yaml) | mapped | Vendor `AEREL` from pharmaverseadam `adae` on refresh. Not a phase 1 input. |
| OCMQ membership (narrow, broad, organ system) | F3, and every OCMQ table | not in `adae`; pharmaverseadam `adae` has no query columns (checked for FMQ, OCMQ, SMQ, CQ names) | none | missing | F3 is out of scope on the demo data until the FDA OCMQ term list is vendored as a reference dataset in the #77 style. The F2/F3 engine is written against one grouping column, so F3 is F2 with the OCMQ column in place of `AEBODSYS`, and needs no further code. |

## ADLB

The phase 0 derivations run over adbds-shaped long results. `Derive_ULNMultiple()` needs participant, test, numeric result and ULN. `Derive_AbnormalityLevel()` additionally needs the unit for the absolute-basis rows, sex for the HDL and hemoglobin rows, and baseline for the baseline_multiple, baseline_percent_decrease and baseline_change rows (creatinine, eGFR, hemoglobin). `Derive_ExtremeValueFlag()` needs the unit to pick the US or SI row. Baseline and study day are not in `adbds`, so they are marked below with a decision.

| ADaM variable | Needed by | Example data | Mapped_* | State | Decision |
| --- | --- | --- | --- | --- | --- |
| `USUBJID` | F5 to F8, F15 to F20; all three derivations | `adbds$USUBJID` (364 subjects, of which 254 are in `adsl`) | `Mapped_LB$subjid` (LB.yaml) | found | Engines inner-join to ADSL. The 110 synthetic hepatology and nephrology subjects stay for the widgets and fall out of every arm-based FDA figure. |
| `PARAM` | every lab figure; parameter lookup in `FDA_AbnormalityLevels` and `FDA_ExtremeValues` | `adbds$TEST` (23 lab tests, names such as "Alanine Aminotransferase", "Bilirubin") | `Mapped_LB$lbtstnam` (LB.yaml; saf0001.yaml) | found | The contract keys on the test name, as `Input_HysLaw()` already does through `lMeasureValues`. The #77 lookup from test name to FDA parameter lives with the reference data. |
| `PARAMCD` | none of the figures; convenient for lookups | not in `adbds` (`adeg` has it) | none | derived | Derive from the test name inside the #77 lookup. Not a contract column. |
| `AVAL` | every lab figure; all derivations | `adbds$STRESN` (no missing values) | `Mapped_LB$lbstresn` as gsm.safety declares it in saf0001.yaml. gsm.mapping's standard LB.yaml names the numeric result `rptresn`; the `lbst` names are gsm.safety's own extension. | found | Contract name `STRESN`. The `Mapped_*` path keeps `lbstresn` because saf0001 already declares it and `Input_HysLaw()` defaults to it. The `rptresn` naming split is recorded on the hub requirement for gsm.mapping. |
| `AVALU` | US versus SI routing in Tables 56 to 60; every absolute-basis level; every extreme-value threshold | `adbds$STRESU`. Bilirubin appears in both umol/L (1654 rows, pilot) and mg/dL (256 rows, synthetic CLD cohort). Hemoglobin is mmol/L, hematocrit is "1", platelets and lymphocytes are GI/L. | none in LB.yaml | found | The derivations match on unit per row and return a missing flag with a reason when no `FDA_ExtremeValues` or absolute-basis row matches, which is why `FDA_ExtremeValues` is long by UnitSystem. On the demo data hemoglobin, hematocrit, platelet and lymphocyte thresholds therefore do not apply (Table 59 is in g/dL, percent and cells per microlitre). A unit-conversion table is a follow-on, not phase 1. `Mapped_*` studies supply a unit column named `lbstresu`. |
| `ANRHI` | F7, F8 (xULN axes); every uln_multiple row of Tables 56 and 57 | `adbds$STNRHI` (missing on 1663 rows, all of them Weight; every lab row has one) | `Mapped_LB$lbstnrhi` (saf0001.yaml); not in gsm.mapping's LB.yaml | found | Contract name `STNRHI`. Rows without a ULN get no xULN and are counted in the footnote, as `Input_HysLaw()` already does. |
| `ANRLO` | optional low side of `Derive_ULNMultiple()`; no figure | `adbds$STNRLO` | none | found | Optional in the contract. |
| `BASE` | F6, F9 (change from baseline), F15, F22 (baseline axis), the baseline-relative bases of Table 56 and 57 | not in `adbds` (`adeg` has it); pharmaverseadam `adlb` has it | none | derived | Derive once in a shared helper, not per engine: `BASE` is the value on the row flagged `ABLFL` for that subject and test. |
| `CHG` | F6, F9; Table 35 | not in `adbds` (`adeg` has it) | none | derived | `STRESN` minus `BASE`. |
| `ABLFL` | baseline definition for everything above | not in `adbds` (`adeg` has it) | none | derived | Derive as the last non-missing row at `VISIT` "Baseline" per subject and test. Verified: lab rows are unique per subject, test and visit, and 99.6 percent of pilot subjects have a Baseline row. Vendor `ABLFL` on refresh as a cross-check. |
| `ADY` | the 30-day pairing window of F7 and F8 (guide 2.4.4.2, 2.4.4.3); F12 intervals; F13 last record; mapping unscheduled visits to the nearest scheduled visit (2.4); any on-treatment window | not in `adbds`, which carries no dates. pharmaverseadam `adlb$ADY` is present on every row for the same 254 subjects. | derive from `Mapped_LB$lb_dt` minus `Mapped_SUBJ$firstdosedate` plus one (LB.yaml, SUBJ.yaml) | missing | Vendor `ADY` from pharmaverseadam `adlb` into `adbds.csv.gz` for the pilot rows, joining on `USUBJID`, test, visit and value. The synthetic cohorts get no `ADY`. Until vendored, F7 and F8 on the demo data plot independent peaks without the 30-day window and the footnote says so, which is what `Input_HysLaw()` does today. |
| `AVISIT` | the x axis of F5, F6, F16 to F20 | `adbds$VISIT`: Baseline, SCREENING 1 and 2, Week 2 to Week 26, Unscheduled n.m | none in LB.yaml. gsm.core's `Raw_LB` carries `visnam`, and `R/SafetyCensus.R` reads `visnam`; `safety_census.yaml` records that the standard mapping has no visit (gsm.safety#58). | found | Contract name `VISIT`. The `Mapped_*` path uses `visnam` when the source supplies it. Screening and unscheduled rows are excluded from visit-axis figures on the demo data and the footnote says so; the guide's nearest-visit mapping needs `ADY` and arrives with it. |
| `AVISITN` | ordering the visit axis | `adbds$VISITNUM`, two schemes in one frame (see above) | none | found | Engines order visits within a parameter by `VISITNUM` and never compare `VISITNUM` across parameters. A refresh must not renumber; pharmaverseadam `adlb` keeps the lab scheme. |
| `ONTRTFL` | last-on-treatment tables (T52, T53); no phase 1 figure | not in `adbds`; pharmaverseadam `adlb` has it | none | missing | Derive from `ADY` between `TRTSDT` and `TRTEDT` once both are vendored. Phase 1 needs only postbaseline, which is any row after the baseline row within a parameter. |
| `SEX` | HDL rows of Table 56; hemoglobin rows of Table 57 | `adbds$SEX` | `Mapped_SUBJ$sex` by join | found | Use as found. |
| `TRT01A` | grouping of every lab figure | `adbds$ARM` | none | found | As the ADSL row. |
| Panel coverage | which panels each figure family can draw on the demo | present: sodium, potassium, chloride, glucose, calcium, phosphate, protein, albumin, BUN, creatinine, urate, ALT, AST, ALP, GGT, bilirubin, cholesterol, leukocytes, hemoglobin, hematocrit, erythrocytes, platelets, lymphocytes. Absent: bicarbonate, magnesium, CPK, amylase, lipase, eGFR, HDL, LDL, triglycerides, neutrophils, eosinophils, PT, PTT, INR. | not applicable | missing | The absent analytes are out of scope on the demo data. Liver biochemistry is complete, so F7, F8 and F18 render in full. General chemistry, kidney function, lipids and hematology render for the analytes present. eGFR is not derived: it needs age, sex and race on the lab frame and a formula choice that belongs to the sponsor. pharmaverseadam `adlb` adds only CK, eosinophils, basophils and monocytes, so a refresh does not close this gap. |

## ADVS

ADVS maps onto the vital-sign rows of `adbds`, so every column shares the ADLB decision unless the row says otherwise. gsm.mapping's `Mapped_VS` is wide (VS.yaml: `sysbp`, `diabp`, `pulse`, `temp`, `resp`, `weight`, `height`, `bmi`, `bsa`, plus `visit`, `vs_dt`, `vsperf_std`), so the `Mapped_*` path pivots it long before the contract applies.

| ADaM variable | Needed by | Example data | Mapped_* | State | Decision |
| --- | --- | --- | --- | --- | --- |
| `USUBJID` | F9, F10, F21, F22 | `adbds$USUBJID` on vital-sign rows (254 subjects, all in `adsl`) | `Mapped_VS$subjid` (VS.yaml) | found | Key. |
| `PARAM` | F9 and F10 name systolic and diastolic blood pressure, heart rate, respiratory rate and temperature (guide 2.5.1, 2.5.2.1); Table 60 lists pulse, systolic, diastolic, respiration, temperature | `adbds$TEST`: Systolic Blood Pressure, Diastolic Blood Pressure, Pulse Rate, Temperature, Weight | the wide column names `sysbp`, `diabp`, `pulse`, `temp`, `resp`, `weight` become the parameter after the pivot | found | Pulse Rate stands in for heart rate and the footnote says so. Weight is present but not a guide parameter. |
| Respiratory rate parameter | F9, F10 panel; Table 60 row | absent from `adbds`; pharmaverseadam `advs` has no respiration parameter either | `Mapped_VS$resp` (VS.yaml) | missing | Out of scope on the demo data. The engines are parameterized, so the panel appears wherever a study supplies it. |
| `AVAL` | every VS figure; `Derive_ExtremeValueFlag()` | `adbds$STRESN` | the pivoted wide value | found | Contract name `STRESN`. |
| `AVALU` | Table 60 routing (temperature in F or C) | `adbds$STRESU`: mmHg, BEATS/MIN, C, kg | none in VS.yaml | found | Temperature is in C and matches Table 60's C column. `Mapped_*` studies supply a unit per pivoted parameter. |
| `BASE` | F9, F22 | not in `adbds`; pharmaverseadam `advs` has it | none | derived | As ADLB. |
| `CHG` | F9 | not in `adbds` | none | derived | As ADLB. |
| `ABLFL` | baseline definition | not in `adbds` | none | derived | As ADLB. 99.6 percent of pilot subjects have a Baseline systolic row. |
| `ADY` | nearest-visit mapping (guide 2.5), F13 last record | not in `adbds`; pharmaverseadam `advs$ADY` is present | derive from `Mapped_VS$vs_dt` minus `Mapped_SUBJ$firstdosedate` plus one | missing | Vendor `ADY` from pharmaverseadam `advs` alongside the ADLB vendoring. No phase 1 VS figure needs it before then. |
| `AVISIT` | the x axis of F10, F21 | `adbds$VISIT` | `Mapped_VS$visit` (VS.yaml) | found | As ADLB. |
| `AVISITN` | visit order | `adbds$VISITNUM` (the vital-sign scheme, Week n numbered n) | none | found | As ADLB: order within a parameter only. |
| `TRT01A` | grouping | `adbds$ARM` | none | found | As the ADSL row. |

## Summary

| Domain | Columns needed | Found | Mapped | Derived | Missing | Decisions |
| --- | --- | --- | --- | --- | --- | --- |
| ADSL | 9 | 5 | 3 | 1 | 0 | Vendor `TRTSDT`, `TRTEDT`, `TRTDURD`, `DTHFL`, `DTHDT`, `SAFFL`, `SEX`, `AGE` from pharmaverseadam `adsl` into `adsl.csv.gz`. Derive the safety population from first dose. Arm is an engine argument; `Mapped_*` data renders one arm. Interim F1 uses `EOSDY` and `EOSSTT`. |
| ADAE | 13 | 8 | 1 | 1 | 3 | Derive `TRTEMFL` from `ASTDY`. Vendor `AEOUT`, `AESDTH`, `AEREL` from pharmaverseadam `adae`. `AEACN` and OCMQ are out of scope on the demo data; F3 waits for a vendored OCMQ term list and reuses the F2 engine. |
| ADLB | 17 | 10 | 0 | 4 | 3 | Derive `BASE`, `CHG`, `ABLFL` from the Baseline visit in one shared helper. Vendor `ADY` from pharmaverseadam `adlb`; until then no 30-day window on F7 and F8. `ONTRTFL` follows `ADY`. Absent analytes are out of scope on the demo data. Units route the FDA tables per row. |
| ADVS | 12 | 7 | 0 | 3 | 2 | Same derivations as ADLB on the vital-sign rows of `adbds`. Vendor `ADY` from pharmaverseadam `advs`. Respiratory rate is out of scope on the demo data. Pulse Rate stands in for heart rate. `Mapped_VS` pivots long. |
| Total | 51 | 30 | 4 | 9 | 8 | Two vendoring passes (ADSL columns; `ADY` on the long domains), one derivation helper (baseline, change, TEAE), and three declared demo exclusions (OCMQ, `AEACN`, absent parameters). |

Every one of the 51 rows carries a state, and every `mapped`, `derived` and `missing` row carries its decision. Nothing is blocked.

## The column contract for phase 1

Every lab and vital-sign engine codes against one long frame. The default names are the adbds spelling, so the demo data runs with no renaming. Each engine takes the column names as arguments in the gsm.core style (`strIDCol`, `strMeasureCol`, `strValueCol`, `strULNCol` are already the names `Input_HysLaw()` uses), so an ADaM frame or a pivoted `Mapped_*` frame runs by passing the names in the last two columns.

| Role | Default (adbds) | ADaM | Mapped_* |
| --- | --- | --- | --- |
| participant | `USUBJID` | `USUBJID` | `subjid` |
| parameter | `TEST` | `PARAM` | `lbtstnam`; the pivoted `Mapped_VS` column name |
| value | `STRESN` | `AVAL` | `lbstresn` (saf0001.yaml; gsm.mapping standard is `rptresn`) |
| unit | `STRESU` | `AVALU` (pharmaverseadam carries `LBSTRESU`, `VSSTRESU`) | `lbstresu`, supplied by the study |
| lower normal | `STNRLO` | `ANRLO` | none; optional |
| upper normal | `STNRHI` | `ANRHI` | `lbstnrhi` (saf0001.yaml) |
| visit | `VISIT` | `AVISIT` | `visnam` (gsm.core `Raw_LB`); `visit` (`Mapped_VS`) |
| visit order | `VISITNUM` | `AVISITN` | none; falls back to first appearance |
| study day | `ADY` (to be vendored) | `ADY` | `lb_dt` or `vs_dt` minus `firstdosedate` plus one |
| baseline flag | `ABLFL` (derived) | `ABLFL` | derived from visit |
| sex | `SEX` | `SEX` | `sex` (`Mapped_SUBJ`) |
| treatment arm | `ARM` | `TRT01A` | none; one arm |

Three rules travel with the contract. Baseline is the last non-missing row flagged as baseline per participant and parameter, and postbaseline is every later row of that parameter. Visits are ordered within a parameter only. Rows failing `Derive_ExtremeValueFlag()` are dropped from the mean-change engine and counted in its footnote; visits with data from fewer than 10 percent of participants in every arm are dropped from every over-time engine (guide 2.4.2, 2.5.1).

The participant-level frame the KM engine codes against is `USUBJID`, `ARM`, `TRTSDT`, `TRTEDT`, `TRTDURD`, `EOSDY`, `EOSSTT`, `DTHFL`, with the `Mapped_*` equivalents `subjid`, none, `firstdosedate`, none, `timeontreatment`, `timeonstudy`, `compyn`, `death_dt`. The event-level frame the AE engines code against is `USUBJID`, `ARM`, `AEBODSYS`, `AEDECOD`, `AESER`, `ASTDY`, `TRTEMFL`, with the `Mapped_*` equivalents `subjid`, none, `mdrsoc_nsv`, `mdrpt_nsv`, `aeser`, derived from `aest_dt`, derived.

---
This note was drafted by Claude Code using Fable 5.1.
