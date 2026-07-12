test_that("safety_histogram workflow renders an HTML report from ExampleData (#30, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "safety_histogram.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  strOutputDir <- tempfile("safety_histogram")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "safety_histogram[.]html$")
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
