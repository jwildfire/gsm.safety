# The twelfth widget (#71). Unlike the other eleven this one takes two data
# frames, because the endpoint is composed from the events rather than
# pre-derived: `dfResults` says who had an event and when, `dfPopulation` says
# who was at risk and for how long. Neither can be inferred from the other —
# a participant with no qualifying event is censored, not absent.

dfTteEvents <- function() {
  dfAE <- ExampleData("adae")
  # The bundled adverse events carry one all-blank placeholder row per
  # participant with no events, so the AE renderers' denominator covers the
  # whole safety population. Those rows are not events, and this chart takes
  # its denominator from the population frame instead.
  dfAE[nzchar(dfAE$AEDECOD), ]
}

lTteSettings <- function() {
  list(
    endpoint_label = "Time to first treatment-emergent adverse event",
    event_filters = list(
      list(value_col = "AEBODSYS", label = "Body System"),
      list(value_col = "AEDECOD", label = "Preferred Term"),
      list(value_col = "AESER", label = "Serious"),
      list(value_col = "AESEV", label = "Severity")
    ),
    filters = list(
      list(value_col = "ARM", label = "Treatment Group")
    )
  )
}

test_that("Widget_TimeToEvent returns an htmlwidget carrying both frames (#71)", {
  dfResults <- dfTteEvents()
  dfPopulation <- ExampleData("adsl")
  lSettings <- lTteSettings()

  lWidget <- Widget_TimeToEvent(dfResults, dfPopulation, lSettings = lSettings)

  expect_s3_class(lWidget, c("Widget_TimeToEvent", "htmlwidget"))
  expect_named(lWidget$x, c("lData", "lSettings", "bDebug"))
  expect_identical(lWidget$x$lData$events, dfResults)
  expect_identical(lWidget$x$lData$population, dfPopulation)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_TimeToEvent passes width, height, and elementId through (#71)", {
  lWidget <- Widget_TimeToEvent(
    dfTteEvents(),
    ExampleData("adsl"),
    width = "100%",
    height = "600px",
    elementId = "time-to-event-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "time-to-event-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_TimeToEvent rejects invalid inputs via the time-to-event contract (#71)", {
  dfResults <- dfTteEvents()
  dfPopulation <- ExampleData("adsl")

  expect_error(Widget_TimeToEvent("not a data.frame", dfPopulation))
  expect_error(Widget_TimeToEvent(dfResults, "not a data.frame"), "population")

  # Each frame is checked against its own requiredSettings: the population's
  # follow-up column is not satisfied by an events column of the same name.
  expect_error(
    Widget_TimeToEvent(
      dfResults,
      dfPopulation,
      lSettings = list(fu_day_col = "ASTDY")
    ),
    "ASTDY.*fu_day_col"
  )
  expect_error(
    Widget_TimeToEvent(
      dfResults,
      dfPopulation,
      lSettings = list(event_day_col = "EOSDY")
    ),
    "EOSDY.*event_day_col"
  )
})

test_that("Widget_TimeToEvent renders standalone HTML carrying both frames (#71)", {
  dfResults <- dfTteEvents()
  dfPopulation <- ExampleData("adsl")

  lWidget <- Widget_TimeToEvent(
    dfResults,
    dfPopulation,
    lSettings = lTteSettings()
  )
  strReportPath <- file.path(tempfile("Widget_TimeToEvent"), "tte.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  # The binding must reach the module, and it must feed it BOTH frames — a
  # wrapper that calls neither raises no error and looks identical on disk.
  expect_match(strHTML, "SafetyViz.timeToEvent(", fixed = TRUE)
  expect_match(strHTML, "x.lData.events", fixed = TRUE)
  expect_match(strHTML, "x.lData.population", fixed = TRUE)
  # A value only the events frame carries, and one only the population does.
  expect_match(strHTML, "APPLICATION SITE ERYTHEMA", fixed = TRUE)
  expect_match(strHTML, "EOSSTT", fixed = TRUE)
})

test_that("time_to_event workflow renders an HTML report from ExampleData (#71)", {
  strWorkflowPath <- system.file(
    "workflow", "4_modules", "time_to_event.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  strOutputDir <- tempfile("time_to_event")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(
      dfResults = dfTteEvents(),
      dfPopulation = ExampleData("adsl")
    )
  )

  expect_match(strReportPath, "time_to_event[.]html$")
  expect_true(file.exists(strReportPath))

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "SafetyViz.timeToEvent(", fixed = TRUE)
  expect_match(strHTML, "EOSSTT", fixed = TRUE)
})
