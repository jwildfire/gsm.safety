test_that("Widget_Histogram returns an htmlwidget carrying the histogram payload (#30)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(
    group_by = "ARM",
    display_normal_range = TRUE
  )

  lWidget <- Widget_Histogram(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_Histogram", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_Histogram passes width, height, and elementId through (#30)", {
  dfResults <- ExampleData("adbds")

  lWidget <- Widget_Histogram(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "histogram-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "histogram-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_Histogram rejects invalid inputs via the histogram contract (#30)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_Histogram("not a data.frame"))
  expect_error(
    Widget_Histogram(dfResults, lSettings = list(measure_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_Histogram renders standalone HTML with the SafetyViz bundle and data (#30)", {
  dfResults <- ExampleData("adbds")
  dfSubset <- dfResults[dfResults$TEST %in% c("Albumin", "Bilirubin"), ]

  lWidget <- Widget_Histogram(dfSubset, lSettings = list(group_by = "ARM"))
  strReportPath <- file.path(tempfile("Widget_Histogram"), "histogram.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"group_by\":\"ARM\"", fixed = TRUE)
})

test_that("no shipped histogram settings pass the two settings safety.viz v1.10.0 removed (#158)", {
  # safety.viz v1.10.0 removed the histogram's `test_normality` and
  # `compare_distributions` (safety.viz#188): the chart draws no p-value and
  # warns in the console when given either. The package must not ship them in
  # its workflow, examples or help.
  chrRemoved <- c("test_normality", "compare_distributions")

  lWorkflow <- yaml::read_yaml(system.file(
    "workflow", "4_modules", "safety_histogram.yaml",
    package = "gsm.safety"
  ))
  expect_length(intersect(names(lWorkflow$meta$lSettings), chrRemoved), 0)

  strRoot <- testthat::test_path("..", "..")
  chrSources <- file.path(strRoot, c(
    "R/Widget_Histogram.R",
    "inst/examples/histogram.R",
    "pkgdown/menus/examples/Example_Histogram.Rmd"
  ))
  for (strSource in chrSources[file.exists(chrSources)]) {
    strText <- paste(readLines(strSource, warn = FALSE), collapse = "\n")
    for (strSetting in chrRemoved) {
      expect_no_match(strText, strSetting, fixed = TRUE, info = basename(strSource))
    }
  }
})
