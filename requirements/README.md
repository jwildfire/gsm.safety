# Requirement matrices

One Markdown matrix per specification gsm.safety implements. Today there is one: [fda-stf.md](fda-stf.md), the figures of the FDA *Standard Safety Tables and Figures: Integrated Guide* v2.0 and the cross-cutting rules they share. The safety.viz renderers keep their own matrices in [safety.viz `requirements/`](https://github.com/jwildfire/safety.viz/tree/dev/requirements); this directory uses the same shape so that a static rendering here and an interactive rendering there can cite one requirement ID.

| Matrix | Scope | Rows |
| --- | --- | ---: |
| [fda-stf.md](fda-stf.md) | 22 FDA ST&F figures (`FDA-FIG-001` to `FDA-FIG-022`) and 16 cross-cutting rules (`FDA-RULE-001` to `FDA-RULE-016`) | 38 |

## How rows are keyed

- Every requirement row starts with an ID matching `<PREFIX>-<AREA>-<NUM>`, the pattern the safety.viz extractor reads (`/^[A-Z]{2,4}-[A-Z]+-\d+[A-D]?$/`). The prefix is `FDA` for the guide; the area is `FIG` for a numbered figure and `RULE` for a rule the guide states once and several displays read.
- `FDA-FIG-nnn` is the guide's figure number, zero-padded: Figure 7 is `FDA-FIG-007`. The number is stable across guide versions only as long as the guide keeps it, so every row also names the guide version and section it was read from. When a future guide renumbers, the row keeps its ID and its `Source` cell records both numbers.
- `FDA-RULE-nnn` is assigned in filing order and never reused. A rule row names the `Derive_*` function or renderer convention that implements it, so a reader can go from the rule to the code.
- The third cell is the requirement text, as in safety.viz. The columns after it record where the row came from, what renders it, the ADaM domains it reads, its safety.viz twin, the phase that ships it, and the evidence.
- A safety.viz module that renders the same display carries its own module-prefixed rows; the `safety.viz twin` cell names the module (and the safety.viz row where one is the direct counterpart), and the static and interactive evidence pages meet on this file's ID.

## How a test cites an ID

Tests follow the repository's qcthat convention: the `test_that()` name ends with the issue it proves, `(#N)`. A test that proves a requirement row puts the ID in the name before the issue reference, so both can be read off the test name:

```r
test_that("Derive_ULNMultiple divides the result by the record's own ULN (FDA-RULE-001) (#78)", {
  ...
})
```

The `Test/Evidence Link` cell of the row names the test file. `grep -rn 'FDA-RULE-001' tests/testthat/` finds every test that cites a row, and `grep -c '^| FDA-FIG-' requirements/fda-stf.md` prints the figure count (22).

## Adding or changing rows

The matrix and the code that satisfies it live in the same repository, so they change in the same pull request: add or amend the row, cite it from the test that proves it, and move its `Status` from `planned` to `ai-reviewed` (or `needs-jeremy-review` when the wording is a clinical reading rather than a quotation from the guide). A row is never deleted; a superseded row keeps its ID and says what replaced it in `Notes`.

---
This README was drafted by Claude Code using Fable 5.1.
