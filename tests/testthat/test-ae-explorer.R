test_that("Widget_AeExplorer returns an htmlwidget carrying the ae-explorer payload (#41)", {
  dfResults <- ExampleData("adae")
  lSettings <- list(group_col = "ARM")

  lWidget <- Widget_AeExplorer(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_AeExplorer", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_AeExplorer initializes on the default ADAE columns with no settings (#41)", {
  dfResults <- ExampleData("adae")

  lWidget <- Widget_AeExplorer(dfResults)

  expect_s3_class(lWidget, "htmlwidget")
  expect_length(lWidget$x$lSettings, 0)
})

test_that("Widget_AeExplorer passes width, height, and elementId through (#41)", {
  dfResults <- ExampleData("adae")

  lWidget <- Widget_AeExplorer(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "ae-explorer-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "ae-explorer-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_AeExplorer rejects invalid inputs via the ae-explorer contract (#41)", {
  dfResults <- ExampleData("adae")

  expect_error(Widget_AeExplorer("not a data.frame"))
  expect_error(
    Widget_AeExplorer(dfResults, lSettings = list(major_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("ExampleData('adae') carries placeholder rows for AE-free participants (#41)", {
  dfAE <- ExampleData("adae")

  # AE-DATA-001: one placeholder row per participant with no adverse events, so
  # the ae-explorer population denominator covers the whole safety population.
  # Placeholders are marked by a blank System Organ Class.
  bPlaceholder <- !nzchar(dfAE$AEBODSYS) | is.na(dfAE$AEBODSYS)

  expect_gt(sum(bPlaceholder), 0)
  expect_identical(
    length(unique(dfAE$USUBJID[bPlaceholder])),
    sum(bPlaceholder)
  )
  expect_length(intersect(
    dfAE$USUBJID[bPlaceholder],
    dfAE$USUBJID[!bPlaceholder]
  ), 0)
  expect_identical(length(unique(dfAE$USUBJID)), 254L)
})

test_that("Widget_AeExplorer renders standalone HTML with the SafetyViz bundle and data (#41)", {
  dfResults <- ExampleData("adae")

  lWidget <- Widget_AeExplorer(dfResults)
  strReportPath <- file.path(tempfile("Widget_AeExplorer"), "ae.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "SafetyViz.aeExplorer", fixed = TRUE)
})

test_that("ae_explorer workflow renders an HTML report from ExampleData (#41, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "ae_explorer.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adae")

  strOutputDir <- tempfile("ae_explorer")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "ae_explorer[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
})
