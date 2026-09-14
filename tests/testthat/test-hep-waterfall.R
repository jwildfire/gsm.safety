lWaterfallSettings <- function() {
  list(
    studyday_col = "VISITNUM",
    measure_values = list(
      ALT = "Alanine Aminotransferase",
      AST = "Aspartate Aminotransferase",
      TB = "Bilirubin",
      ALP = "Alkaline Phosphatase"
    ),
    arm_col = "ARM",
    placebo_arm = "ABL: Placebo",
    active_arms = list("ABL: Study Drug")
  )
}

test_that("Widget_HepWaterfall returns an htmlwidget carrying the hep-waterfall payload (#49)", {
  dfResults <- ExampleData("adbds_abnbl")
  lSettings <- lWaterfallSettings()

  lWidget <- Widget_HepWaterfall(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_HepWaterfall", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_HepWaterfall passes width, height, and elementId through (#49)", {
  dfResults <- ExampleData("adbds_abnbl")

  lWidget <- Widget_HepWaterfall(
    dfResults,
    lSettings = lWaterfallSettings(),
    width = "100%",
    height = "600px",
    elementId = "hep-waterfall-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "hep-waterfall-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_HepWaterfall rejects invalid inputs via the hep-waterfall contract (#49)", {
  dfResults <- ExampleData("adbds_abnbl")

  expect_error(Widget_HepWaterfall("not a data.frame"))
  expect_error(
    Widget_HepWaterfall(
      dfResults,
      lSettings = c(lWaterfallSettings(), list(value_col = "NOT_A_COLUMN"))
    ),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_HepWaterfall renders standalone HTML with the SafetyViz bundle and the abnormal-baseline cohort (#49)", {
  dfResults <- ExampleData("adbds_abnbl")

  lWidget <- Widget_HepWaterfall(dfResults, lSettings = lWaterfallSettings())
  strReportPath <- file.path(tempfile("Widget_HepWaterfall"), "waterfall.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "ABL-1001", fixed = TRUE)
})

test_that("hep_waterfall workflow renders an HTML report from ExampleData (#49)", {
  strWorkflowPath <- system.file(
    "workflow", "4_modules", "hep_waterfall.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  dfResults <- ExampleData("adbds_abnbl")

  strOutputDir <- tempfile("hep_waterfall")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  )

  expect_match(strReportPath, "hep_waterfall[.]html$")
  expect_true(file.exists(strReportPath))

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "ABL-1001", fixed = TRUE)
})
