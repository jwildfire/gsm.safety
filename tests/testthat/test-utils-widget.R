test_that("BuildWidgetPayload returns the htmlwidget x payload for valid input (#31)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(group_by = "ARM")

  lPayload <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "histogram"
  )

  expect_named(lPayload, c("dfResults", "lSettings", "bDebug"))
  expect_identical(lPayload$dfResults, dfResults)
  expect_identical(lPayload$lSettings, lSettings)
  expect_false(lPayload$bDebug)
})

test_that("BuildWidgetPayload serializes empty settings as a JSON object (#31)", {
  lPayload <- BuildWidgetPayload(
    dfResults = ExampleData("adbds"),
    lSettings = list(),
    strModule = "histogram"
  )

  expect_identical(
    as.character(jsonlite::toJSON(lPayload$lSettings, auto_unbox = TRUE)),
    "{}"
  )
})

test_that("BuildWidgetPayload errors when a schema-default column is missing (#31)", {
  dfResults <- ExampleData("adbds")
  dfResults$TEST <- NULL

  expect_error(
    BuildWidgetPayload(
      dfResults = dfResults,
      lSettings = list(),
      strModule = "histogram"
    ),
    "TEST.*measure_col"
  )
})

test_that("BuildWidgetPayload errors when a settings override names a missing column (#31)", {
  expect_error(
    BuildWidgetPayload(
      dfResults = ExampleData("adbds"),
      lSettings = list(value_col = "NOT_A_COLUMN"),
      strModule = "histogram"
    ),
    "NOT_A_COLUMN.*value_col"
  )
})

test_that("BuildWidgetPayload checks nested object settings like ae-timelines color (#31)", {
  dfAE <- ExampleData("adae")

  expect_no_error(
    BuildWidgetPayload(
      dfResults = dfAE,
      lSettings = list(),
      strModule = "ae-timelines"
    )
  )
  expect_error(
    BuildWidgetPayload(
      dfResults = dfAE,
      lSettings = list(color = list(value_col = "NOT_A_COLUMN")),
      strModule = "ae-timelines"
    ),
    "NOT_A_COLUMN.*color\\$value_col"
  )
})

test_that("BuildWidgetPayload validates its inputs (#31)", {
  dfResults <- ExampleData("adbds")

  expect_error(BuildWidgetPayload(dfResults = "nope", strModule = "histogram"))
  expect_error(
    BuildWidgetPayload(
      dfResults = dfResults,
      lSettings = dfResults,
      strModule = "histogram"
    )
  )
  expect_error(
    BuildWidgetPayload(dfResults = dfResults, strModule = "not-a-module"),
    "not-a-module"
  )
})

test_that("SaveWidgetReport writes a self-contained HTML report and returns its path (#31)", {
  dfResults <- ExampleData("adbds")
  dfAlbumin <- dfResults[dfResults$TEST == "Albumin", ]
  strOutputDir <- file.path(tempfile("SaveWidgetReport"), "nested")

  strReportPath <- SaveWidgetReport(
    Widget_Histogram(dfAlbumin),
    strOutputDir = strOutputDir,
    strOutputFile = "histogram"
  )

  expect_true(file.exists(strReportPath))
  expect_match(strReportPath, "histogram[.]html$")

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "SafetyViz", fixed = TRUE)
  expect_match(strHTML, "Albumin", fixed = TRUE)
})

test_that("SaveWidgetReport keeps an existing .html extension and validates inputs (#31)", {
  dfResults <- ExampleData("adbds")
  dfAlbumin <- dfResults[dfResults$TEST == "Albumin", ]
  strOutputDir <- tempfile("SaveWidgetReport")

  strReportPath <- SaveWidgetReport(
    Widget_Histogram(dfAlbumin),
    strOutputDir = strOutputDir,
    strOutputFile = "report.html"
  )
  expect_match(basename(strReportPath), "^report[.]html$")

  expect_error(
    SaveWidgetReport(
      "not a widget",
      strOutputDir = strOutputDir,
      strOutputFile = "report"
    )
  )
})
