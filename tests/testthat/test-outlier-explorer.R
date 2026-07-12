test_that("Widget_OutlierExplorer returns an htmlwidget carrying the outlier-explorer payload (#35)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(
    normal_range_method = "None",
    groups = list(
      list(value_col = "ARM", label = "Treatment Group")
    )
  )

  lWidget <- Widget_OutlierExplorer(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_OutlierExplorer", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_OutlierExplorer passes width, height, and elementId through (#35)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_OutlierExplorer(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "outlier-explorer-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "outlier-explorer-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_OutlierExplorer rejects invalid inputs via the outlier-explorer contract (#35)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_OutlierExplorer("not a data.frame"))
  expect_error(
    Widget_OutlierExplorer(
      dfResults,
      lSettings = list(measure_col = "NOT_A_COLUMN")
    ),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_OutlierExplorer renders standalone HTML with the SafetyViz bundle and data (#35)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  lWidget <- Widget_OutlierExplorer(
    dfSubset,
    lSettings = list(normal_range_method = "None")
  )
  strReportPath <- file.path(tempfile("Widget_OutlierExplorer"), "outlier.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"normal_range_method\":\"None\"", fixed = TRUE)
})

test_that("safety_outlier_explorer workflow renders an HTML report from ExampleData (#35, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "safety_outlier_explorer.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  strOutputDir <- tempfile("safety_outlier_explorer")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "safety_outlier_explorer[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "Treatment Group", fixed = TRUE)
  expect_match(strHTML, "Participant ID", fixed = TRUE)
})
