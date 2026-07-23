test_that("Widget_DeltaDelta returns an htmlwidget carrying the delta-delta payload (#33)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(
    measure_x = "Alanine Aminotransferase",
    measure_y = "Aspartate Aminotransferase",
    add_regression_line = TRUE
  )

  lWidget <- Widget_DeltaDelta(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_DeltaDelta", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_DeltaDelta passes width, height, and elementId through (#33)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_DeltaDelta(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "delta-delta-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "delta-delta-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_DeltaDelta rejects invalid inputs via the delta-delta contract (#33)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_DeltaDelta("not a data.frame"))
  expect_error(
    Widget_DeltaDelta(dfResults, lSettings = list(measure_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_DeltaDelta renders standalone HTML with the SafetyViz bundle and data (#33)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[
    dfResults$TEST %in% c("Alanine Aminotransferase", "Aspartate Aminotransferase"),
  ]

  lWidget <- Widget_DeltaDelta(
    dfSubset,
    lSettings = list(measure_x = "Alanine Aminotransferase")
  )
  strReportPath <- file.path(tempfile("Widget_DeltaDelta"), "delta-delta.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"measure_x\":\"Alanine Aminotransferase\"", fixed = TRUE)
})

test_that("safety_delta_delta workflow renders an HTML report from ExampleData (#33, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "safety_delta_delta.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[
    dfResults$TEST %in% c("Alanine Aminotransferase", "Aspartate Aminotransferase"),
  ]

  strOutputDir <- tempfile("safety_delta_delta")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "safety_delta_delta[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"measure_x\":\"Alanine Aminotransferase\"", fixed = TRUE)
  expect_match(strHTML, "Treatment Group", fixed = TRUE)
})
