lHepSettings <- function() {
  list(
    studyday_col = "VISITNUM",
    measure_values = list(
      ALT = "Alanine Aminotransferase",
      AST = "Aspartate Aminotransferase",
      TB = "Bilirubin",
      ALP = "Alkaline Phosphatase"
    )
  )
}

test_that("Widget_HepExplorer returns an htmlwidget carrying the hep-explorer payload (#40)", {
  dfResults <- ExampleData("adbds")
  lSettings <- lHepSettings()

  lWidget <- Widget_HepExplorer(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_HepExplorer", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_HepExplorer passes width, height, and elementId through (#40)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_HepExplorer(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "hep-explorer-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "hep-explorer-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_HepExplorer rejects invalid inputs via the hep-explorer contract (#40)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_HepExplorer("not a data.frame"))
  expect_error(
    Widget_HepExplorer(dfResults, lSettings = list(value_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_HepExplorer renders standalone HTML with the SafetyViz bundle and data (#40)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[
    dfResults$TEST %in% c(
      "Alanine Aminotransferase",
      "Aspartate Aminotransferase",
      "Bilirubin",
      "Alkaline Phosphatase"
    ),
  ]

  lWidget <- Widget_HepExplorer(dfSubset, lSettings = lHepSettings())
  strReportPath <- file.path(tempfile("Widget_HepExplorer"), "hep.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"ALT\":\"Alanine Aminotransferase\"", fixed = TRUE)
})

test_that("hep_explorer workflow renders an HTML report from ExampleData (#40, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "hep_explorer.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds")
  dfResults <- dfResults[
    dfResults$TEST %in% c(
      "Alanine Aminotransferase",
      "Aspartate Aminotransferase",
      "Bilirubin",
      "Alkaline Phosphatase"
    ),
  ]

  strOutputDir <- tempfile("hep_explorer")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "hep_explorer[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"ALT\":\"Alanine Aminotransferase\"", fixed = TRUE)
})
