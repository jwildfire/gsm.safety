# Qualifying the eleven census metrics (`saf0005`–`saf0015`)

Recorded 2026-08-21 · [gsm.safety#58](https://github.com/jwildfire/gsm.safety/issues/58) ·
[obot.roadmap#274](https://github.com/jwildfire/obot.roadmap/issues/274) ·
[D0023](https://jwildfire.github.io/obot.roadmap/reports/decisions/2026-08-20-safety-census-rebuild/)

Installed with the package: `inst/qualification/census-metrics-qualification.md`
in the repository, and
`system.file("qualification", "census-metrics-qualification.md",
package = "gsm.safety")` once installed
([#63](https://github.com/jwildfire/gsm.safety/issues/63)). The record travels
with the thing it qualifies, and every figure below is compared with the code
by the test suite in every context it runs in — `R CMD check` included.

Passing tests are not the check, and the D0023 design says so directly: a test
asserting that the code does what the code does would not have caught any of
the defects this rebuild exists to fix. So every census figure is measured
twice on the same study, by two routes that share no code, and the result is
recorded here. This is step two's counterpart to
[`death-count-qualification.md`](death-count-qualification.md), which did the
same for `saf0004`.

## The two routes

- **Route B — the records, read directly.** Base R over `gsm.core::lSource`:
  the subject, randomisation, lab, adverse-event and study-completion domains,
  each intersected with the enrolled population. No mapping package, no metric,
  no gsm helper.
- **Route A — the pipeline.** The standard `gsm.mapping` mapping into the
  `Mapped_*` domains, then each `saf00**` workflow end to end.

Reproduce either with:

```bash
Rscript tools/qualify-census-metrics.R
```

The script exits non-zero if any pair disagrees. The same two routes run in the
suite as `tests/testthat/test-qualification-census-metrics.R`.

## What was measured

Bundled study `AA-AA-000-0000`, from `gsm.core::lSource`.
`gsm.core` 1.3.1, `gsm.mapping` 1.1.6, R 4.3.3.

The anchor for every figure below is the enrolled population: **762**
participants of the 1000 in `Raw_SUBJ` have `enrollyn == "Y"`, and
`Mapped_SUBJ` is exactly those 762.

| Metric | Figure | Route A | Route B | `SafetyCensus()` today |
|---|---|---|---|---|
| `saf0005` | Enrolled participants | 762 | 762 | 762 |
| `saf0006` | Randomised participants | 577 | 577 | *blank* |
| `saf0007` | Participants dosed | 762 | 762 | 744 |
| `saf0008` | Participant-days on study | 26,754 | 26,754 | 73.2 years |
| `saf0009` | Participant-days on treatment | 10,761 | 10,761 | 29.5 years |
| `saf0010` | Participants with a lab result | 598 | 598 | 598 |
| `saf0011` | Participants with an ECG | *no domain* | *no domain* | *blank* |
| `saf0012` | Participants with a reported AE | 661 | 661 | 661 |
| `saf0013` | Participants with a disposition record | 77 | 76 | 100 |
| `saf0014` | Participants who completed | 19 | 19 | *inside a table* |
| `saf0015` | Participants who discontinued | 9 | 9 | *inside a table* |

Every published row carries `Denominator = 762`, `Score = Numerator`, and an
**empty** flag — these metrics do not flag, and empty is not zero (D0023.3).

## The findings

Five things did not come out the way the design or step one's notes say. None
of them changes what was decided; all of them change an arithmetic the decision
was argued with.

### 1. `SafetyCensus()` reports **four** deaths on this study, not one

D0023 and step one's notes both say the function reports **1**. Measured on
`gsm.core` 1.3.1 with the standard mapped domains it reports **4**.

One is what the function reported on `gsm.core` 1.2.0, where a single
participant's discontinuation reason said `Death`; that study now has four. The
function does not anchor its death count to the enrolled population, so it
counts all four — three of whom are enrolled and one of whom (`S78705`) is not.

The correction the death metric makes is therefore **4 → 13**, not 1 → 13. It
is still the largest figure in this release and still the reason the rebuild
exists; it is not a thirteenfold correction. `death-count-qualification.md` and
the v1.3.0 release notes carry a correction note pointing here.

### 2. Step one's note that the discontinuation reason names "four participants
of whom one is enrolled" has it backwards

Three of the four are enrolled (`S62400`, `S44367`, `S33412`); one is not
(`S78705`). The three participants excluded from `saf0004`'s count are two from
the death domain (`S42425`, `S97688`) and that one. Step one's headline figure
of 13 is unaffected and was re-measured here: 12 death-domain participants of
whom 10 are enrolled, plus 4 discontinuation-reason participants of whom 3 are
enrolled, no overlap, giving 13 of 762.

### 3. "Dosed" moves *up*, to every enrolled participant

The design says the dosed count "stops being inferred from treatment time being
greater than zero". On this study that inference gives 744; a recorded
first-dose date gives **762**. The 18 participants in the gap have a first-dose
date and `timeontreatment == 0` — dosed and stopped inside a day.

Worth knowing before anyone reads 762 as a validation of the fix: on this study
`firstdosedate` is identical to `enrolldt` and to `firstparticipantdate` for
every enrolled participant. The synthetic study does not distinguish enrolment
from dosing, so it cannot exercise the difference between `saf0005` and
`saf0007`. The metric is right; the study is not a test of it.

### 4. The "lab and ECG domains against the visit schedule" cannot be read that
way

Data completeness is the twelfth metric on the issue's list and it is **not in
this release**. Two facts found while scoping it:

- `Mapped_LB` under the standard mapping carries `studyid`, `subjid`,
  `toxgrg_nsv` and `lb_dt` — and no visit column at all. `gsm.mapping`'s LB
  spec does not declare `visnam`, and a *metric's* `Mapped_*` spec does not
  propagate back into `Ingest()`'s column subsetting (verified: `saf0001`
  declares `Mapped_LB.lbtstnam` and the standard pipeline still drops it). So a
  coverage figure cannot key on a lab row's visit label, which is what D0023
  intends, but it cannot key on it *at all* without a change upstream.
- `gsm.mapping` ships no ECG mapping, so half of the stated input does not
  exist for any study today (see finding 5).

With C2 answered as "the participants whose time on study reaches that visit",
the expected count needs a per-visit study day. `Mapped_VISIT` supplies
per-participant visit dates (8 folders per participant on this study) but no
scheduled day, and `Mapped_SUBJ` carries no enrolment date, so the study day
would have to be inferred and a lab result attributed to a visit by date match.
Both are definitional choices D0023 explicitly leaves as "a declared input
rather than an assumption", and they belong with the coverage table in the
report step rather than being guessed here. Carried, and named in the release
notes rather than quietly dropped.

### 5. `saf0011` cannot be measured on any study available today

The ECG count is written, declares `Mapped_EG` — the domain name the demo
study's census script and `saf0002` already use — and behaves correctly when
the domain is absent: it **stops**, rather than publishing a zero. But
`gsm.mapping` ships no EG mapping and `gsm.core::lSource` has no `Raw_EG`, so
there is no second route to check it against. Its qualification is structural
(unit and workflow tests on a fixture), not a measurement, and the suite
asserts that no bundled ECG domain has appeared — if one ever does, that test
fails and the metric must be measured rather than left passing.

## What moves on the demo study's safety page

Nothing yet: `SafetyCensus()` is untouched by this release, and step four is
what rewires it. When it is rewired, these are the figures that change and why
each was wrong:

| Figure | From | To | Why it was wrong |
|---|---|---|---|
| Randomised to an arm | *blank* | 577 | read a treatment-arm column no standard domain carries |
| Received study drug | 744 | 762 | inferred from treatment time, not from a recorded first dose |
| Deaths | 4 | 13 | matched a discontinuation reason, never read the death domain, and counted participants who were never enrolled |
| Participants with a disposition record | 100 | 76 | counted every identifier in the disposition domain, enrolled or not |
| Participants with an ECG | *blank* | *absent, loudly* | reported blank where the domain is missing rather than saying so |

Person-years on study (73.2) and on treatment (29.5) are unchanged as
quantities — 26,754 and 10,761 days over 365.25 — but the metrics publish days,
and the report divides.

## They land in the reporting model beside the flagging metrics

`gsm.reporting::MakeMetric()` (1.1.5) turns all fifteen definitions in
`inst/workflow/2_metrics/` into one tibble: fifteen rows, the three flagging
metrics carrying a `Threshold` and the twelve census metrics carrying `NA`.
That is what makes a descriptive metric invisible to gsm.kri's risk-score
builder, which skips any metric with no threshold — a census figure cannot move
a site's score. Checked directly rather than assumed; not asserted in the suite,
because gsm.safety does not depend on `gsm.reporting` and taking that dependency
for one assertion is a larger change than it is worth.

## The snapshot is version-pinned, on purpose

The bundled study is not fixed. gsm.safety tracks `gsm.core`'s `main` branch,
and between **1.2.0 and 1.3.1** that study changed under the same name: the
enrolled population went from 760 to 762 and the discontinuation-reason deaths
from 1 to 4. Every figure on this page was measured on 1.3.1.

So the qualification test asserts two different kinds of thing. The identities
between the two routes — that they land on the same number, that no count
exceeds the enrolled population, that completed and discontinued together
cannot exceed the participants who have a disposition record, that nobody is on
treatment longer than on study — hold on any version and are always checked.
The exact counts are a snapshot, asserted only against the `gsm.core` version
they were measured on; a different version skips those tests with the recorded
and the live numbers both named in the skip reason, and a pointer to this file.

Re-qualifying is a deliberate act: run the reproducer, update this file and the
`RECORDED_CENSUS` list in the test. A clinical figure whose reference study
moved should be re-checked by a person, not silently re-derived.

## Absent, empty, zero

The three states every one of these metrics keeps apart, checked in
`tests/testthat/test-Input_Participants.R`,
`tests/testthat/test-Input_ParticipantDays.R` and
`tests/testthat/test-workflow-census-metrics.R` — the last of them for all
eleven metrics from one table, because eleven hand-written blocks are eleven
chances to leave one rule out.

| State | The study said | The metric does |
|---|---|---|
| Absent | no domain, or no declared column in it | errors |
| Empty | a domain with no rows | publishes no row, and warns |
| Zero | a populated domain naming nobody | publishes `0` |

And one state the counting metrics have that `saf0004` does not: a subject
domain with no rows at all is **no denominator**, which is not a denominator of
zero. Nothing is published, and the warning says why.

The absent state is checked in its strongest form: for every census metric,
every column its definition declares is dropped in turn and the metric has to
stop — 34 combinations across the eleven, plus the four of `saf0004`, all of
which stop. A column a definition declares but no step reads would be a promise
to a reader that nothing keeps; this is what makes that impossible to leave
behind when a definition is edited later.

`gsm.core::CheckSpec()` **errors on a missing data.frame but only warns on a
missing declared column**. Verified again here against 1.3.1 rather than taken
from the design, which calls the false-zero defect "fixed by construction".
Declaring the columns in each yaml is necessary but not sufficient — every one
of these metrics checks its own columns and stops, in one shared guard called
by all of them.
