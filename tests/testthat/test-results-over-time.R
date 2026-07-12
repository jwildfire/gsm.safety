test_that("Widget_ResultsOverTime returns an htmlwidget carrying the payload (#34)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(
    group_by = "ARM",
    time_col = "VISIT"
  )

  lWidget <- Widget_ResultsOverTime(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_ResultsOverTime", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_ResultsOverTime passes width, height, and elementId through (#34)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_ResultsOverTime(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "results-over-time-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "results-over-time-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_ResultsOverTime rejects invalid inputs via the results-over-time contract (#34)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_ResultsOverTime("not a data.frame"))
  expect_error(
    Widget_ResultsOverTime(
      dfResults,
      lSettings = list(measure_col = "NOT_A_COLUMN")
    ),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_ResultsOverTime renders standalone HTML with the SafetyViz bundle and data (#34)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  lWidget <- Widget_ResultsOverTime(dfSubset, lSettings = list(group_by = "ARM"))
  strReportPath <- file.path(tempfile("Widget_ResultsOverTime"), "results-over-time.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"group_by\":\"ARM\"", fixed = TRUE)
})

test_that("safety_results_over_time workflow renders an HTML report from ExampleData (#34, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "safety_results_over_time.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  strOutputDir <- tempfile("safety_results_over_time")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "safety_results_over_time[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"group_by\":\"ARM\"", fixed = TRUE)
  expect_match(strHTML, "Treatment Group", fixed = TRUE)
})
