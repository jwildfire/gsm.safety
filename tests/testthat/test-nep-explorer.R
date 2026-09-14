test_that("Widget_NepExplorer returns an htmlwidget carrying the nep-explorer payload (#49)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_NepExplorer(dfResults)

  expect_s3_class(lWidget, c("Widget_NepExplorer", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_NepExplorer passes width, height, and elementId through (#49)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_NepExplorer(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "nep-explorer-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "nep-explorer-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_NepExplorer rejects invalid inputs via the nep-explorer contract (#49)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_NepExplorer("not a data.frame"))
  expect_error(
    Widget_NepExplorer(dfResults, lSettings = list(value_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_NepExplorer renders standalone HTML with the SafetyViz bundle and the AKI cohort (#49)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[dfResults$TEST == "Creatinine", ]

  lWidget <- Widget_NepExplorer(
    dfSubset,
    lSettings = list(
      filters = list(
        list(value_col = "ARM", label = "Treatment Group"),
        list(value_col = "SEX", label = "Sex")
      )
    )
  )
  strReportPath <- file.path(tempfile("Widget_NepExplorer"), "nep.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "AKI-", fixed = TRUE)
})

test_that("nep_explorer workflow renders an HTML report from ExampleData (#49)", {
  strWorkflowPath <- system.file(
    "workflow", "4_modules", "nep_explorer.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[dfResults$TEST == "Creatinine", ]

  strOutputDir <- tempfile("nep_explorer")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "nep_explorer[.]html$")
  expect_true(file.exists(strReportPath))

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "AKI-", fixed = TRUE)
})
