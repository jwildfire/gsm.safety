test_that("BuildWidgetPayload returns the htmlwidget x payload for valid input (#31)", {
  dfResults <- ExampleData("adbds")
  lSettings <- list(group_by = "ARM")

  lPayload <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "histogram"
  )

  expect_named(lPayload, c("dfResults", "lSettings", "bDebug"))
  expect_identical(lPayload$dfResults, dfResults)
  expect_identical(lPayload$lSettings, lSettings)
  expect_false(lPayload$bDebug)
})

test_that("BuildWidgetPayload serializes empty settings as a JSON object (#31)", {
  lPayload <- BuildWidgetPayload(
    dfResults = ExampleData("adbds"),
    lSettings = list(),
    strModule = "histogram"
  )

  expect_identical(
    as.character(jsonlite::toJSON(lPayload$lSettings, auto_unbox = TRUE)),
    "{}"
  )
})

test_that("BuildWidgetPayload errors when a schema-default column is missing (#31)", {
  dfResults <- ExampleData("adbds")
  dfResults$TEST <- NULL

  expect_error(
    BuildWidgetPayload(
      dfResults = dfResults,
      lSettings = list(),
      strModule = "histogram"
    ),
    "TEST.*measure_col"
  )
})

test_that("BuildWidgetPayload errors when a settings override names a missing column (#31)", {
  expect_error(
    BuildWidgetPayload(
      dfResults = ExampleData("adbds"),
      lSettings = list(value_col = "NOT_A_COLUMN"),
      strModule = "histogram"
    ),
    "NOT_A_COLUMN.*value_col"
  )
})

test_that("BuildWidgetPayload checks nested object settings like ae-timelines color (#31)", {
  dfAE <- ExampleData("adae")

  expect_no_error(
    BuildWidgetPayload(
      dfResults = dfAE,
      lSettings = list(),
      strModule = "ae-timelines"
    )
  )
  expect_error(
    BuildWidgetPayload(
      dfResults = dfAE,
      lSettings = list(color = list(value_col = "NOT_A_COLUMN")),
      strModule = "ae-timelines"
    ),
    "NOT_A_COLUMN.*color\\$value_col"
  )
})

test_that("BuildWidgetPayload validates its inputs (#31)", {
  dfResults <- ExampleData("adbds")

  expect_error(BuildWidgetPayload(dfResults = "nope", strModule = "histogram"))
  expect_error(
    BuildWidgetPayload(
      dfResults = dfResults,
      lSettings = dfResults,
      strModule = "histogram"
    )
  )
  expect_error(
    BuildWidgetPayload(dfResults = dfResults, strModule = "not-a-module"),
    "not-a-module"
  )
})

test_that("SaveWidgetReport writes a self-contained HTML report and returns its path (#31)", {
  dfResults <- ExampleData("adbds")
  dfAlbumin <- dfResults[dfResults$TEST == "Albumin", ]
  strOutputDir <- file.path(tempfile("SaveWidgetReport"), "nested")

  strReportPath <- SaveWidgetReport(
    Widget_Histogram(dfAlbumin),
    strOutputDir = strOutputDir,
    strOutputFile = "histogram"
  )

  expect_true(file.exists(strReportPath))
  expect_match(strReportPath, "histogram[.]html$")

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "SafetyViz", fixed = TRUE)
  expect_match(strHTML, "Albumin", fixed = TRUE)
})

test_that("SaveWidgetReport keeps an existing .html extension and validates inputs (#31)", {
  dfResults <- ExampleData("adbds")
  dfAlbumin <- dfResults[dfResults$TEST == "Albumin", ]
  strOutputDir <- tempfile("SaveWidgetReport")

  strReportPath <- SaveWidgetReport(
    Widget_Histogram(dfAlbumin),
    strOutputDir = strOutputDir,
    strOutputFile = "report.html"
  )
  expect_match(basename(strReportPath), "^report[.]html$")

  expect_error(
    SaveWidgetReport(
      "not a widget",
      strOutputDir = strOutputDir,
      strOutputFile = "report"
    )
  )
})

# --- Multi-dataset contracts (#71) -------------------------------------------
# time-to-event is the first module whose contract names two datasets rather
# than one: `events` + `population`, each declaring its own requiredSettings.
# The single-`dfResults` payload cannot carry two frames, so BuildWidgetPayload
# reads the dataset names off the schema instead of assuming one.

dfTteEvents <- function() {
  ExampleData("adae")[, c("USUBJID", "ARM", "AEBODSYS", "AEDECOD", "AESER", "AESEV", "ASTDY")]
}

dfTtePopulation <- function() {
  ExampleData("adsl")
}

test_that("BuildWidgetPayload carries both frames of a two-dataset contract (#71)", {
  dfEvents <- dfTteEvents()
  dfPopulation <- dfTtePopulation()

  lPayload <- BuildWidgetPayload(
    lData = list(events = dfEvents, population = dfPopulation),
    lSettings = list(),
    strModule = "time-to-event"
  )

  expect_named(lPayload, c("lData", "lSettings", "bDebug"))
  expect_named(lPayload$lData, c("events", "population"))
  expect_identical(lPayload$lData$events, dfEvents)
  expect_identical(lPayload$lData$population, dfPopulation)
  expect_false(lPayload$bDebug)
})

test_that("BuildWidgetPayload checks each dataset's own requiredSettings (#71)", {
  dfEvents <- dfTteEvents()
  dfPopulation <- dfTtePopulation()

  # fu_day_col belongs to the population frame, not the events frame: naming a
  # column that exists only in the events data must still fail.
  expect_error(
    BuildWidgetPayload(
      lData = list(events = dfEvents, population = dfPopulation),
      lSettings = list(fu_day_col = "ASTDY"),
      strModule = "time-to-event"
    ),
    "ASTDY.*fu_day_col"
  )

  # ...and the reverse: event_day_col is checked against the events frame.
  expect_error(
    BuildWidgetPayload(
      lData = list(events = dfEvents, population = dfPopulation),
      lSettings = list(event_day_col = "EOSDY"),
      strModule = "time-to-event"
    ),
    "EOSDY.*event_day_col"
  )
})

test_that("BuildWidgetPayload errors when a two-dataset contract is missing a frame (#71)", {
  expect_error(
    BuildWidgetPayload(
      lData = list(events = dfTteEvents()),
      strModule = "time-to-event"
    ),
    "population"
  )
  expect_error(
    BuildWidgetPayload(
      lData = list(events = dfTteEvents(), population = "not a data.frame"),
      strModule = "time-to-event"
    ),
    "population"
  )
})

test_that("BuildWidgetPayload refuses a single frame for a two-dataset contract (#71)", {
  expect_error(
    BuildWidgetPayload(
      dfResults = dfTteEvents(),
      strModule = "time-to-event"
    ),
    "events.*population|two datasets|lData"
  )
})

test_that("BuildWidgetPayload still takes dfResults for a one-dataset contract (#71)", {
  # The eleven existing widgets must be untouched by the generalization.
  lPayload <- BuildWidgetPayload(
    dfResults = ExampleData("adbds"),
    strModule = "nep-explorer"
  )
  expect_named(lPayload, c("dfResults", "lSettings", "bDebug"))
})
