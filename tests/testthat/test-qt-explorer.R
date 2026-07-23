lQtSettings <- function() {
  list(
    placebo_arm = "Placebo",
    filters = list(
      list(value_col = "SEX", label = "Sex"),
      list(value_col = "RACE", label = "Race"),
      list(value_col = "SITE", label = "Site")
    )
  )
}

test_that("Widget_QtExplorer returns an htmlwidget carrying the qt-explorer payload (#42)", {
  dfResults <- ExampleData("adeg")
  lSettings <- lQtSettings()

  lWidget <- Widget_QtExplorer(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_QtExplorer", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_QtExplorer initializes on the default ADEG columns with no settings (#42)", {
  dfResults <- ExampleData("adeg")

  lWidget <- Widget_QtExplorer(dfResults)

  expect_s3_class(lWidget, "htmlwidget")
  expect_length(lWidget$x$lSettings, 0)
})

test_that("Widget_QtExplorer passes width, height, and elementId through (#42)", {
  dfResults <- ExampleData("adeg")

  lWidget <- Widget_QtExplorer(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "qt-explorer-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "qt-explorer-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_QtExplorer rejects invalid inputs via the qt-explorer contract (#42)", {
  dfResults <- ExampleData("adeg")

  expect_error(Widget_QtExplorer("not a data.frame"))
  expect_error(
    Widget_QtExplorer(dfResults, lSettings = list(value_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("ExampleData('adeg') supplies the ECG measures qt-explorer expects (#42)", {
  dfEG <- ExampleData("adeg")

  expect_s3_class(dfEG, "data.frame")
  expect_true(all(
    c(
      "USUBJID", "ARM", "VISIT", "VISITNUM", "PARAMCD", "TEST",
      "STRESU", "STRESN", "BASE", "CHG", "ABLFL"
    ) %in% names(dfEG)
  ))
  expect_true(all(c("QTcF", "QTcB", "Heart Rate") %in% unique(dfEG$TEST)))
  expect_true(is.numeric(dfEG$STRESN))
  expect_true(is.numeric(dfEG$BASE))
  expect_true(is.numeric(dfEG$CHG))
  expect_true("Placebo" %in% unique(dfEG$ARM))
  expect_identical(length(unique(dfEG$USUBJID)), 254L)
})

test_that("ExampleData('adeg') QTc values are physiologically plausible (#42)", {
  dfEG <- ExampleData("adeg")

  # Regression guard for safety.viz#79. The v1.4.0 extract took QTcF/QTcB from the
  # CDISC Pilot 01 source's own pre-derived parameters, which are corrected against
  # a collected RR that contradicts the recorded heart rate — inflating them by
  # ~80 ms to a median QTcF of 555 ms, above the highest ICH E14 category boundary,
  # which saturated every threshold in the chart. A median corrected QT interval
  # above 500 ms is not a population, it is uncleaned data: fail loudly if a future
  # re-vendor reintroduces one.
  for (strMeasure in c("QTcF", "QTcB")) {
    vValues <- dfEG$STRESN[dfEG$TEST == strMeasure]
    expect_lt(stats::median(vValues), 500)
    expect_gt(stats::median(vValues), 350)
  }

  # Heart rate is measured, not derived, and should sit in a resting range.
  vHR <- dfEG$STRESN[dfEG$TEST == "Heart Rate"]
  expect_gt(stats::median(vHR), 50)
  expect_lt(stats::median(vHR), 90)
})

test_that("Widget_QtExplorer renders standalone HTML with the SafetyViz bundle and data (#42)", {
  dfResults <- ExampleData("adeg")

  lWidget <- Widget_QtExplorer(dfResults, lSettings = lQtSettings())
  strReportPath <- file.path(tempfile("Widget_QtExplorer"), "qt.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "QTcF", fixed = TRUE)
  expect_match(strHTML, "SafetyViz.qtExplorer", fixed = TRUE)
})

test_that("qt_explorer workflow renders an HTML report from ExampleData (#42, #38)", {
  strWorkflowPath <- system.file(
    "workflow", "3_reports", "qt_explorer.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adeg")

  strOutputDir <- tempfile("qt_explorer")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "qt_explorer[.]html$")
  expect_true(file.exists(strReportPath))
  expect_identical(
    normalizePath(dirname(strReportPath), winslash = "/"),
    normalizePath(strOutputDir, winslash = "/")
  )

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "QTcF", fixed = TRUE)
})
