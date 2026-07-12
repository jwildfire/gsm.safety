test_that("Widget_AeTimelines returns an htmlwidget carrying the ae-timelines payload (#36)", {
  dfResults <- ExampleData("adae")
  lSettings <- list(
    color = list(value_col = "AESEV", label = "Severity"),
    sort_participants = "earliest"
  )

  lWidget <- Widget_AeTimelines(dfResults, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_AeTimelines", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_AeTimelines passes width, height, and elementId through (#36)", {
  dfResults <- ExampleData("adae")

  lWidget <- Widget_AeTimelines(
    dfResults,
    width = "100%",
    height = "600px",
    elementId = "ae-timelines-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "ae-timelines-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_AeTimelines rejects invalid inputs via the ae-timelines contract (#36)", {
  dfResults <- ExampleData("adae")

  expect_error(Widget_AeTimelines("not a data.frame"))
  expect_error(
    Widget_AeTimelines(dfResults, lSettings = list(id_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN"
  )
})

test_that("Widget_AeTimelines renders standalone HTML with the SafetyViz bundle and data (#36)", {
  dfResults <- ExampleData("adae")
  dfSubset <- dfResults[
    dfResults$AEDECOD %in% c("APPLICATION SITE ERYTHEMA", "APPLICATION SITE PRURITUS"),
  ]

  lWidget <- Widget_AeTimelines(
    dfSubset,
    lSettings = list(sort_participants = "earliest")
  )
  strReportPath <- file.path(tempfile("Widget_AeTimelines"), "ae_timelines.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  expect_match(strHTML, "\"sort_participants\":\"earliest\"", fixed = TRUE)
})
