test_that("Widget_ShiftPlot returns an htmlwidget carrying the shift-plot payload (#32)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(
    baseline_visits = list("Baseline"),
    comparison_visits = list("Week 26")
  )

  lWidget <- Widget_ShiftPlot(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_ShiftPlot", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_ShiftPlot passes width, height, and elementId through (#32)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_ShiftPlot(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "shift-plot-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "shift-plot-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_ShiftPlot rejects invalid inputs via the shift-plot contract (#32)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_ShiftPlot("not a data.frame"))
  expect_error(
    Widget_ShiftPlot(dfResults, lSettings = list(measure_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_ShiftPlot renders standalone HTML with the SafetyViz bundle and data (#32)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  lWidget <- Widget_ShiftPlot(
    dfSubset,
    lSettings = list(baseline_visits = list("Baseline"))
  )
  strReportPath <- file.path(tempfile("Widget_ShiftPlot"), "shift.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"baseline_visits\":[\"Baseline\"]", fixed = TRUE)
})

test_that("safety_shift_plot workflow renders an HTML report from ExampleData (#32, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "safety_shift_plot.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  strOutputDir <- tempfile("safety_shift_plot")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "safety_shift_plot[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"baseline_visits\":\"Baseline\"", fixed = TRUE)
  expect_match(strHTML, "Treatment Group", fixed = TRUE)
})
