# The census report (#61, D0023). Step three of four in the SafetyCensus
# rebuild.
#
# The report reads what the metrics published and computes nothing of its own.
# That is not a style preference: a helper that recalculates a figure the
# metrics already produce is a second counting lane, which is the defect the
# whole rebuild exists to remove. The tests below are written to fail if one
# ever appears — the figures are checked against *deliberately wrong* results,
# so a helper that recomputed the truth would be caught by its correctness.
#
# Two presentation rules are load-bearing rather than cosmetic and are asserted
# here: participant-days are published as days and presented as years, and
# nothing in the report flags.
#
# The third rule is about absence. The thirteenth metric, data coverage, did
# not land (#58). A study with no coverage figure renders the report *without*
# a coverage section: an empty coverage table would read as a study with no
# data rather than a report with no metric, which is the exact confusion a
# coverage figure exists to prevent.

CENSUS_REPORT_SETTINGS <- function() {
  list(
    Sections = list(
      list(Title = "Population", Metrics = list("saf0005", "saf0004")),
      list(Title = "Exposure", Metrics = list("saf0008")),
      list(Title = "Follow-up", Metrics = list("saf0011"))
    ),
    PersonTime = list(
      Metrics = list("saf0008"),
      DaysPerYear = 365.25,
      Unit = "person-years"
    ),
    Coverage = list(Metrics = list())
  )
}

CENSUS_REPORT_METRICS <- function() {
  data.frame(
    ID = c("saf0004", "saf0005", "saf0008", "saf0011", "saf0099"),
    MetricID = paste0(
      "Analysis_", c("saf0004", "saf0005", "saf0008", "saf0011", "saf0099")
    ),
    GroupLevel = "Study",
    Metric = c(
      "Deaths (Study)",
      "Enrolled Participants (Study)",
      "Participant-Days on Study (Study)",
      "Participants With an ECG (Study)",
      "Lab Coverage by Visit (Study)"
    ),
    Numerator = c(
      "Participants Who Died",
      "Enrolled Participant",
      "Participant-Days on Study",
      "Participant With an ECG",
      "Participant With a Result"
    ),
    Denominator = c(
      "Enrolled Participant",
      "Enrolled Participant",
      "Participant With Recorded Person-Time",
      "Enrolled Participant",
      "Participant Expected at the Visit"
    ),
    stringsAsFactors = FALSE
  )
}

# Deliberately not the bundled study's real figures. A helper that recomputed
# anything would disagree with these, and every assertion below would fail.
CENSUS_REPORT_RESULTS <- function() {
  data.frame(
    GroupID = "ZZ-ZZ-999-9999",
    GroupLevel = "Study",
    Numerator = c(7, 500, 36525),
    Denominator = c(500, 500, 500),
    Metric = c(7 / 500, 1, 36525 / 500),
    Score = c(7, 500, 36525),
    Flag = NA_integer_,
    MetricID = paste0("Analysis_", c("saf0004", "saf0005", "saf0008")),
    SnapshotDate = as.Date("2026-08-21"),
    StudyID = "ZZ-ZZ-999-9999",
    stringsAsFactors = FALSE
  )
}

CensusFigure <- function(dfFigures, strID) {
  dfFigures[dfFigures$ID == strID, , drop = FALSE]
}

RenderCensusReport <- function(
    dfResults = CENSUS_REPORT_RESULTS(),
    dfMetrics = CENSUS_REPORT_METRICS(),
    lSettings = CENSUS_REPORT_SETTINGS()) {
  strOutputDir <- tempfile("census_report")
  dir.create(strOutputDir, recursive = TRUE)
  strPath <- Report_SafetyCensus(
    dfFigures = Report_CensusFigures(dfResults, dfMetrics, lSettings),
    dfCoverage = Report_CensusCoverage(dfResults, dfMetrics, lSettings),
    dfProvenance = Report_CensusProvenance(dfResults, dfMetrics, lSettings),
    dfResults = dfResults,
    strOutputDir = strOutputDir,
    strOutputFile = "safety_census"
  )
  list(
    path = strPath,
    html = paste(readLines(strPath, warn = FALSE), collapse = "\n")
  )
}

# ---- The report reads; it does not count ------------------------------------

test_that("every presented figure is the number the metric published (#61)", {
  dfResults <- CENSUS_REPORT_RESULTS()
  dfFigures <- Report_CensusFigures(
    dfResults, CENSUS_REPORT_METRICS(), CENSUS_REPORT_SETTINGS()
  )

  # Counts are carried through untouched. These are not the bundled study's
  # figures; a helper that recounted anything could not produce them.
  expect_identical(CensusFigure(dfFigures, "saf0004")$Value, 7)
  expect_identical(CensusFigure(dfFigures, "saf0004")$Denominator, 500)
  expect_identical(CensusFigure(dfFigures, "saf0005")$Value, 500)
  expect_identical(CensusFigure(dfFigures, "saf0005")$Denominator, 500)
})

test_that("a change in the published result moves the presented figure by exactly that much (#61)", {
  # The law a reading report obeys and a counting one does not: output is a
  # function of the published row alone.
  for (nNumerator in c(0, 1, 3, 199, 761)) {
    dfResults <- CENSUS_REPORT_RESULTS()
    dfResults$Numerator[dfResults$MetricID == "Analysis_saf0004"] <- nNumerator
    dfFigures <- Report_CensusFigures(
      dfResults, CENSUS_REPORT_METRICS(), CENSUS_REPORT_SETTINGS()
    )
    expect_identical(
      CensusFigure(dfFigures, "saf0004")$Value, as.numeric(nNumerator)
    )
  }
})

test_that("the report needs no study domain to render a figure (#61)", {
  # The strongest form of "computes nothing": the report is handed results and
  # metric definitions and nothing else. There is no domain to count from, so
  # a recalculating helper could not run at all.
  expect_named(
    formals(Report_CensusFigures),
    c("dfResults", "dfMetrics", "lSettings")
  )
  expect_named(
    formals(Report_CensusCoverage),
    c("dfResults", "dfMetrics", "lSettings")
  )
  expect_named(
    formals(Report_CensusProvenance),
    c("dfResults", "dfMetrics", "lSettings")
  )
})

# ---- Days published, years presented ----------------------------------------

test_that("participant-days are presented as years and the days stay visible (#61)", {
  lSettings <- CENSUS_REPORT_SETTINGS()
  dfFigures <- Report_CensusFigures(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), lSettings
  )
  dfDays <- CensusFigure(dfFigures, "saf0008")

  # 36,525 days is exactly 100 years at 365.25.
  expect_identical(dfDays$Value, 100)
  expect_identical(dfDays$Unit, "person-years")
  # The denominator is presented as published: participants, not years.
  expect_identical(dfDays$Denominator, 500)

  # And the published days are still on the page, so the division is checkable.
  dfProvenance <- Report_CensusProvenance(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), lSettings
  )
  expect_identical(
    dfProvenance$Numerator[dfProvenance$ID == "saf0008"], 36525
  )
})

test_that("only the metrics declared as person-time are divided (#61)", {
  lSettings <- CENSUS_REPORT_SETTINGS()
  lSettings$PersonTime$Metrics <- list()
  dfFigures <- Report_CensusFigures(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), lSettings
  )
  expect_identical(CensusFigure(dfFigures, "saf0008")$Value, 36525)
  expect_true(is.na(CensusFigure(dfFigures, "saf0008")$Unit))
})

# ---- Nothing flags ----------------------------------------------------------

test_that("no presented figure carries a flag or a threshold (#61)", {
  lReport <- RenderCensusReport()
  dfFigures <- Report_CensusFigures(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), CENSUS_REPORT_SETTINGS()
  )

  expect_false("Flag" %in% names(dfFigures))
  expect_false("Threshold" %in% names(dfFigures))
  # D0023.3 in the rendered page: no amber, no red, no threshold anywhere.
  expect_false(grepl("amber", lReport$html, ignore.case = TRUE))
  expect_false(grepl("threshold", lReport$html, ignore.case = TRUE))
  expect_false(grepl("flag-red|flag-amber", lReport$html))
})

test_that("a flagged result is refused rather than presented as a census figure (#61)", {
  dfResults <- CENSUS_REPORT_RESULTS()
  dfResults$Flag[dfResults$MetricID == "Analysis_saf0004"] <- 2L
  expect_error(
    Report_CensusFigures(
      dfResults, CENSUS_REPORT_METRICS(), CENSUS_REPORT_SETTINGS()
    ),
    "flag"
  )
})

# ---- Absent is not zero, and not blank --------------------------------------

test_that("a metric that published no row is named as absent, never shown as blank (#61)", {
  lSettings <- CENSUS_REPORT_SETTINGS()
  dfFigures <- Report_CensusFigures(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), lSettings
  )
  # saf0011 is declared in the settings and published nothing on this study.
  expect_identical(nrow(CensusFigure(dfFigures, "saf0011")), 0L)

  dfProvenance <- Report_CensusProvenance(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), lSettings
  )
  expect_identical(
    dfProvenance$Status[dfProvenance$ID == "saf0011"], "no row published"
  )
  expect_true(is.na(dfProvenance$Numerator[dfProvenance$ID == "saf0011"]))

  lReport <- RenderCensusReport()
  expect_match(lReport$html, "Participants With an ECG", fixed = TRUE)
  expect_match(lReport$html, "no row published", fixed = TRUE)
})

test_that("a published zero is a figure and stays one (#61)", {
  dfResults <- CENSUS_REPORT_RESULTS()
  dfResults$Numerator[dfResults$MetricID == "Analysis_saf0004"] <- 0
  dfFigures <- Report_CensusFigures(
    dfResults, CENSUS_REPORT_METRICS(), CENSUS_REPORT_SETTINGS()
  )
  expect_identical(CensusFigure(dfFigures, "saf0004")$Value, 0)
  expect_identical(nrow(CensusFigure(dfFigures, "saf0004")), 1L)
})

# ---- Data coverage: absent, not empty ---------------------------------------

test_that("a study with no coverage figure renders no coverage section (#61)", {
  lReport <- RenderCensusReport()
  expect_false(grepl("Data coverage", lReport$html, ignore.case = TRUE))
  expect_false(grepl("Coverage by visit", lReport$html, ignore.case = TRUE))
})

test_that("a coverage metric that published rows renders the section (#61)", {
  lSettings <- CENSUS_REPORT_SETTINGS()
  lSettings$Coverage$Metrics <- list("saf0099")

  dfResults <- rbind(
    CENSUS_REPORT_RESULTS(),
    data.frame(
      GroupID = c("Week 2", "Week 12"),
      GroupLevel = "Visit",
      Numerator = c(410, 250),
      Denominator = c(500, 300),
      Metric = c(410 / 500, 250 / 300),
      Score = c(410, 250),
      Flag = NA_integer_,
      MetricID = "Analysis_saf0099",
      SnapshotDate = as.Date("2026-08-21"),
      StudyID = "ZZ-ZZ-999-9999",
      stringsAsFactors = FALSE
    )
  )

  dfCoverage <- Report_CensusCoverage(
    dfResults, CENSUS_REPORT_METRICS(), lSettings
  )
  expect_identical(nrow(dfCoverage), 2L)
  expect_identical(dfCoverage$Participants, c(410, 250))
  expect_identical(dfCoverage$Expected, c(500, 300))
  # Presented in the order the metric published them, never sorted by label:
  # alphabetical visit order is the defect D0023 removes.
  expect_identical(dfCoverage$Group, c("Week 2", "Week 12"))

  lReport <- RenderCensusReport(dfResults = dfResults, lSettings = lSettings)
  expect_match(lReport$html, "Data coverage", fixed = TRUE)
  expect_match(lReport$html, "Week 12", fixed = TRUE)
})

test_that("a coverage metric that published nothing renders no coverage section (#61)", {
  # Declared but absent is still absent: the section goes, rather than
  # rendering an empty table that reads as a study with no data.
  lSettings <- CENSUS_REPORT_SETTINGS()
  lSettings$Coverage$Metrics <- list("saf0099")

  dfCoverage <- Report_CensusCoverage(
    CENSUS_REPORT_RESULTS(), CENSUS_REPORT_METRICS(), lSettings
  )
  expect_identical(nrow(dfCoverage), 0L)

  lReport <- RenderCensusReport(lSettings = lSettings)
  expect_false(grepl("Data coverage", lReport$html, ignore.case = TRUE))
})

# ---- What the page says -----------------------------------------------------

test_that("the rendered report presents every figure beside its denominator (#61)", {
  lReport <- RenderCensusReport()

  expect_match(lReport$html, "Safety Census", fixed = TRUE)
  expect_match(lReport$html, "ZZ-ZZ-999-9999", fixed = TRUE)
  expect_match(lReport$html, "Deaths", fixed = TRUE)
  expect_match(lReport$html, "Population", fixed = TRUE)
  expect_match(lReport$html, "Exposure", fixed = TRUE)
  # 7 of 500, and 100 person-years of 500 participants.
  expect_match(lReport$html, "500", fixed = TRUE)
  expect_match(lReport$html, "100", fixed = TRUE)
  expect_match(lReport$html, "person-years", fixed = TRUE)
})

test_that("the report writes one self-contained HTML file (#61)", {
  lReport <- RenderCensusReport()
  expect_match(lReport$path, "safety_census[.]html$")
  expect_true(file.exists(lReport$path))
  expect_match(lReport$html, "<html", fixed = TRUE)
  expect_false(grepl("<script src=\"http", lReport$html, fixed = TRUE))
})

# ---- The workflow -----------------------------------------------------------

CensusReportWorkflow <- function() {
  strPath <- system.file(
    "workflow", "4_modules", "safety_census.yaml",
    package = "gsm.safety"
  )
  if (!nzchar(strPath)) stop("no workflow yaml for safety_census")
  yaml::read_yaml(strPath)
}

test_that("the census report workflow declares a report over the reporting model (#61)", {
  lWorkflow <- CensusReportWorkflow()

  expect_identical(lWorkflow$meta$Type, "Report")
  expect_identical(lWorkflow$meta$ID, "safety_census")
  expect_identical(lWorkflow$meta$Output, "html")
  expect_true(all(
    c("Reporting_Results", "Reporting_Metrics") %in% names(lWorkflow$spec)
  ))
})

test_that("every step of the census report is a gsm.safety report helper (#61)", {
  # The shape @jwildfire named: a workflow calling helpers, not one function
  # doing the work. Any step reaching into a study domain would be a second
  # counting lane.
  lWorkflow <- CensusReportWorkflow()
  chrSteps <- vapply(lWorkflow$steps, function(lStep) lStep$name, character(1))
  expect_true(all(grepl("^(gsm[.]safety::Report_|getwd$)", chrSteps)))
  expect_false(any(grepl("Input_|Mapped_", chrSteps)))
})

test_that("the census report settings name only metrics the package ships (#61)", {
  lWorkflow <- CensusReportWorkflow()
  chrDeclared <- unique(unlist(c(
    lapply(lWorkflow$meta$lSettings$Sections, function(l) l$Metrics),
    lWorkflow$meta$lSettings$PersonTime$Metrics,
    lWorkflow$meta$lSettings$Coverage$Metrics
  )))
  expect_gt(length(chrDeclared), 0)
  for (strID in chrDeclared) {
    expect_true(
      nzchar(system.file(
        "workflow", "2_metrics", paste0(strID, ".yaml"),
        package = "gsm.safety"
      )),
      info = strID
    )
  }
  # The thirteenth metric did not land (#58), so the report ships with no
  # coverage metric to read and renders without that section.
  expect_length(unlist(lWorkflow$meta$lSettings$Coverage$Metrics), 0L)
})

test_that("the census report workflow runs end to end and writes its page (#61)", {
  lWorkflow <- CensusReportWorkflow()

  strOutputDir <- tempfile("safety_census_workflow")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(
      Reporting_Results = CENSUS_REPORT_RESULTS(),
      Reporting_Metrics = CENSUS_REPORT_METRICS()
    )
  )))

  expect_match(strReportPath, "safety_census[.]html$")
  expect_true(file.exists(strReportPath))
  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "Safety Census", fixed = TRUE)
})
