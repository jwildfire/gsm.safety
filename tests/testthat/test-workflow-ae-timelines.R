test_that("ae_timelines workflow renders an HTML report from ExampleData (#36, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "ae_timelines.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adae")
  dfResults <- dfResults[
    dfResults$AEDECOD %in% c("APPLICATION SITE ERYTHEMA", "APPLICATION SITE PRURITUS"),
  ]

  strOutputDir <- tempfile("ae_timelines")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "ae_timelines[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"sort_participants\":\"earliest\"", fixed = TRUE)
  expect_match(strHTML, "Serious Event", fixed = TRUE)
})
