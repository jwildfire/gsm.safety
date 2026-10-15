ANALYZED <- data.frame(
  GroupID = c("AA-AA-000-0000"),
  GroupLevel = "Study",
  Numerator = 12,
  Denominator = 760,
  Metric = 12 / 760,
  Score = 12,
  stringsAsFactors = FALSE
)

test_that("Flag_None leaves the flag empty, never zero (#56)", {
  # gsm.kri's srs0001 risk-score metric publishes Flag = NA and has done so in
  # production throughout: an empty flag is the ecosystem's existing way of
  # saying this number does not flag. A zero would read as measured and fine.
  dfFlagged <- Flag_None(ANALYZED)

  expect_true("Flag" %in% names(dfFlagged))
  expect_true(all(is.na(dfFlagged$Flag)))
  expect_true(is.integer(dfFlagged$Flag))
  expect_false(any(dfFlagged$Flag %in% 0, na.rm = TRUE))
})

test_that("Flag_None carries every row and column through untouched (#56)", {
  dfFlagged <- Flag_None(ANALYZED)

  expect_identical(nrow(dfFlagged), nrow(ANALYZED))
  expect_identical(dfFlagged[, names(ANALYZED)], ANALYZED)
})

test_that("Flag_None hands gsm.core::Summarize() a frame it accepts (#56)", {
  dfSummary <- gsm.core::Summarize(Flag_None(ANALYZED))

  expect_identical(
    names(dfSummary),
    c("GroupID", "GroupLevel", "Numerator", "Denominator", "Metric", "Score", "Flag")
  )
  expect_true(all(is.na(dfSummary$Flag)))
})

test_that("Flag_None survives a metric that published no figure (#56)", {
  dfFlagged <- Flag_None(ANALYZED[0, , drop = FALSE])

  expect_identical(nrow(dfFlagged), 0L)
  expect_true("Flag" %in% names(dfFlagged))
})

test_that("Flag_None refuses to erase a flag another step already set (#56)", {
  dfAnalyzed <- ANALYZED
  dfAnalyzed$Flag <- 2L

  expect_error(Flag_None(dfAnalyzed), "Flag")
  expect_error(Flag_None(ANALYZED[, setdiff(names(ANALYZED), "Score")]), "Score")
  expect_error(Flag_None("not a data.frame"), "data.frame")
})
