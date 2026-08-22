# Qualifying the census report (#61, D0023). Step three of four.
#
# The report's job is to present figures it did not compute, so qualifying it
# is not "does the code do what the code does" — it is whether the numbers a
# reader sees on the page are the numbers recorded in
# design/census-metrics-qualification.md, which were themselves measured twice
# by routes that share no code.
#
# Two directions are checked, because either one alone can rot:
#
#   1. The page against the record. The whole pipeline runs on the bundled
#      study - mapping, the twelve metrics, the reporting model, the report -
#      and every presented figure is compared with the recorded one.
#   2. The record against the design file. The constants below are compared
#      with the qualification table in design/census-metrics-qualification.md,
#      so a figure re-measured in that file and not here shows up as a
#      failure rather than as a quiet disagreement between two documents.
#
# design/ is .Rbuildignore'd, so direction 2 runs under devtools::test() and
# skips under R CMD check. Direction 1 runs wherever the packages are
# installed, and is pinned to the gsm.core the figures were measured on: the
# bundled study moved once already between 1.2.0 and 1.3.1.

# Measured 2026-08-21 against gsm.core 1.3.1 and gsm.mapping 1.1.6, and
# recorded in design/census-metrics-qualification.md.
RECORDED_REPORT <- list(
  gsm.core = "1.3.1",
  StudyID = "AA-AA-000-0000",
  Enrolled = 762,
  # What the metrics publish, and what the report presents where they differ.
  Published = list(
    saf0004 = 13, saf0005 = 762, saf0006 = 577, saf0007 = 762,
    saf0008 = 26754, saf0009 = 10761, saf0010 = 598, saf0012 = 661,
    saf0013 = 76, saf0014 = 19, saf0015 = 9
  ),
  # Participant-days published, person-years presented.
  PersonYears = list(saf0008 = 73.2, saf0009 = 29.5),
  # The one census metric with no domain on any study available today (#58).
  Absent = "saf0011"
)

CensusReportSettings <- function() {
  yaml::read_yaml(system.file(
    "workflow", "4_modules", "safety_census.yaml",
    package = "gsm.safety"
  ))$meta$lSettings
}

# ---- The whole pipeline, on the bundled study -------------------------------

BundledCensusReport <- function() {
  lWorkflows <- suppressWarnings(gsm.core::MakeWorkflowList(
    strNames = c(
      "SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death", "AE", "LB"
    ),
    strPackage = "gsm.mapping"
  ))
  lMapped <- suppressWarnings(suppressMessages({
    lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
    gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(gsm.core::lSource, lSpec))
  }))

  chrIDs <- names(RECORDED_REPORT$Published)
  lMetricWorkflows <- lapply(chrIDs, function(strID) {
    yaml::read_yaml(system.file(
      "workflow", "2_metrics", paste0(strID, ".yaml"),
      package = "gsm.safety"
    ))
  })
  names(lMetricWorkflows) <- chrIDs

  lAnalysis <- suppressWarnings(suppressMessages(
    gsm.core::RunWorkflows(lMetricWorkflows, lMapped)
  ))

  list(
    dfResults = suppressWarnings(suppressMessages(gsm.reporting::BindResults(
      lAnalysis,
      strName = "Analysis_Summary",
      dSnapshotDate = as.Date("2026-08-21"),
      strStudyID = RECORDED_REPORT$StudyID
    ))),
    dfMetrics = suppressWarnings(suppressMessages(
      gsm.reporting::MakeMetric(lMetricWorkflows)
    ))
  )
}

SkipUnlessQualifiedVersion <- function() {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("gsm.reporting")
  skip_if_not_installed("yaml")

  strInstalled <- as.character(utils::packageVersion("gsm.core"))
  if (identical(strInstalled, RECORDED_REPORT$gsm.core)) {
    return(invisible(TRUE))
  }
  # Never a bare skip: the reason names both versions and where the recorded
  # figures live, so a moved study reads as a re-qualification to do rather
  # than as a test that quietly stopped running.
  skip(paste0(
    "The census figures were qualified on gsm.core ", RECORDED_REPORT$gsm.core,
    " and gsm.core ", strInstalled, " is installed. The bundled study moved ",
    "once already between 1.2.0 and 1.3.1. Re-qualify with ",
    "Rscript tools/qualify-census-metrics.R and update ",
    "design/census-metrics-qualification.md."
  ))
}

test_that("every figure the report presents is the qualified figure (#61)", {
  SkipUnlessQualifiedVersion()

  lData <- BundledCensusReport()
  lSettings <- CensusReportSettings()
  dfFigures <- Report_CensusFigures(lData$dfResults, lData$dfMetrics, lSettings)

  for (strID in names(RECORDED_REPORT$Published)) {
    dfRow <- dfFigures[dfFigures$ID == strID, , drop = FALSE]
    expect_identical(nrow(dfRow), 1L, info = strID)

    nExpected <- if (!is.null(RECORDED_REPORT$PersonYears[[strID]])) {
      RECORDED_REPORT$PersonYears[[strID]]
    } else {
      RECORDED_REPORT$Published[[strID]]
    }
    expect_equal(dfRow$Value, nExpected, info = strID)
  }
})

test_that("every figure is presented beside the denominator the metric published (#61)", {
  SkipUnlessQualifiedVersion()

  lData <- BundledCensusReport()
  dfFigures <- Report_CensusFigures(
    lData$dfResults, lData$dfMetrics, CensusReportSettings()
  )
  # Every census figure on this study is counted against the enrolled
  # population; the person-time pair against the participants who contributed
  # it, which on this study is the same 762.
  expect_true(all(dfFigures$Denominator == RECORDED_REPORT$Enrolled))
  expect_true(all(nzchar(dfFigures$DenominatorLabel)))
})

test_that("the participant-days metrics are the only ones the report divides (#61)", {
  SkipUnlessQualifiedVersion()

  lData <- BundledCensusReport()
  lSettings <- CensusReportSettings()
  dfFigures <- Report_CensusFigures(lData$dfResults, lData$dfMetrics, lSettings)
  dfProvenance <- Report_CensusProvenance(
    lData$dfResults, lData$dfMetrics, lSettings
  )

  for (strID in names(RECORDED_REPORT$Published)) {
    nPublished <- dfProvenance$Numerator[dfProvenance$ID == strID]
    # Provenance is what the metric published, always, in the unit it used.
    expect_equal(nPublished, RECORDED_REPORT$Published[[strID]], info = strID)

    nPresented <- dfFigures$Value[dfFigures$ID == strID]
    if (is.null(RECORDED_REPORT$PersonYears[[strID]])) {
      expect_identical(nPresented, nPublished, info = strID)
    } else {
      expect_equal(
        nPresented,
        round(nPublished / lSettings$PersonTime$DaysPerYear, 1),
        info = strID
      )
    }
  }
})

test_that("the metric with no domain is absent from the figures and named on the page (#61)", {
  SkipUnlessQualifiedVersion()

  lData <- BundledCensusReport()
  lSettings <- CensusReportSettings()
  dfFigures <- Report_CensusFigures(lData$dfResults, lData$dfMetrics, lSettings)
  dfProvenance <- Report_CensusProvenance(
    lData$dfResults, lData$dfMetrics, lSettings
  )

  # gsm.mapping ships no EG mapping, so saf0011 stops rather than publishing a
  # zero, and a batch that includes it stops with it — which is why it is not
  # in this study's reporting model at all. The report must not turn that into
  # a blank row.
  expect_identical(nrow(dfFigures[dfFigures$ID == RECORDED_REPORT$Absent, ]), 0L)
  expect_identical(
    dfProvenance$Status[dfProvenance$ID == RECORDED_REPORT$Absent],
    "not run for this study"
  )
})

test_that("a census batch including the ECG metric stops on the missing domain (#61)", {
  SkipUnlessQualifiedVersion()

  # Recorded here because it is the reason the report never sees saf0011 on
  # this study: gsm.core::RunWorkflows() stops the whole batch on a
  # spec-declared input the study does not supply. Loud, and never a zero.
  lWorkflows <- suppressWarnings(gsm.core::MakeWorkflowList(
    strNames = c(
      "SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death", "AE", "LB"
    ),
    strPackage = "gsm.mapping"
  ))
  lMapped <- suppressWarnings(suppressMessages({
    lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
    gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(gsm.core::lSource, lSpec))
  }))
  lECG <- list(saf0011 = yaml::read_yaml(system.file(
    "workflow", "2_metrics", "saf0011.yaml",
    package = "gsm.safety"
  )))

  expect_error(
    suppressWarnings(suppressMessages(gsm.core::RunWorkflows(lECG, lMapped))),
    "Mapped_EG"
  )
})

test_that("the bundled study renders no data-coverage section (#61)", {
  SkipUnlessQualifiedVersion()

  lData <- BundledCensusReport()
  lSettings <- CensusReportSettings()

  strOutputDir <- tempfile("qualified_census")
  dir.create(strOutputDir, recursive = TRUE)
  strPath <- Report_SafetyCensus(
    dfFigures = Report_CensusFigures(lData$dfResults, lData$dfMetrics, lSettings),
    dfCoverage = Report_CensusCoverage(lData$dfResults, lData$dfMetrics, lSettings),
    dfProvenance = Report_CensusProvenance(lData$dfResults, lData$dfMetrics, lSettings),
    dfResults = lData$dfResults,
    strOutputDir = strOutputDir,
    strOutputFile = "safety_census"
  )
  strHTML <- paste(readLines(strPath, warn = FALSE), collapse = "\n")

  # The thirteenth metric did not land (#58). No coverage figure means no
  # coverage section - not an empty one.
  expect_false(grepl("Data coverage", strHTML, ignore.case = TRUE))
  # The qualified figures are on the page.
  expect_match(strHTML, "AA-AA-000-0000", fixed = TRUE)
  expect_match(strHTML, "13", fixed = TRUE)
  expect_match(strHTML, "73.2", fixed = TRUE)
})

# ---- The record against the design file -------------------------------------

QualificationTable <- function() {
  strPath <- testthat::test_path(
    "..", "..", "design", "census-metrics-qualification.md"
  )
  skip_if_not(
    file.exists(strPath),
    "design/ is .Rbuildignore'd and unavailable in this check context"
  )
  chrLines <- readLines(strPath, warn = FALSE)
  chrRows <- grep("^[|] `saf[0-9]{4}` [|]", chrLines, value = TRUE)
  expect_gt(length(chrRows), 0)

  lRows <- lapply(chrRows, function(strRow) {
    chrCells <- trimws(strsplit(strRow, "|", fixed = TRUE)[[1]])
    chrCells <- chrCells[nzchar(chrCells)]
    list(
      ID = gsub("`", "", chrCells[1], fixed = TRUE),
      RouteA = suppressWarnings(as.numeric(gsub(",", "", chrCells[3], fixed = TRUE))),
      RouteB = suppressWarnings(as.numeric(gsub(",", "", chrCells[4], fixed = TRUE)))
    )
  })
  stats::setNames(lRows, vapply(lRows, function(l) l$ID, character(1)))
}

test_that("the recorded figures are the ones the qualification file records (#61)", {
  lTable <- QualificationTable()

  for (strID in names(RECORDED_REPORT$Published)) {
    if (identical(strID, "saf0004")) next # qualified in death-count-qualification.md
    expect_false(is.null(lTable[[strID]]), info = strID)
    expect_equal(
      lTable[[strID]]$RouteA, RECORDED_REPORT$Published[[strID]],
      info = strID
    )
    # The two routes agreed when it was recorded; if that ever stops being
    # true in the file, this test says so before the report quotes it.
    expect_equal(lTable[[strID]]$RouteA, lTable[[strID]]$RouteB, info = strID)
  }

  # The metric with no second route is recorded as having none.
  expect_true(is.na(lTable[[RECORDED_REPORT$Absent]]$RouteA))
})

test_that("the presented person-years are the recorded participant-days divided (#61)", {
  lTable <- QualificationTable()
  lSettings <- CensusReportSettings()

  for (strID in names(RECORDED_REPORT$PersonYears)) {
    expect_equal(
      round(lTable[[strID]]$RouteA / lSettings$PersonTime$DaysPerYear, 1),
      RECORDED_REPORT$PersonYears[[strID]],
      info = strID
    )
  }
})

test_that("the death count is the figure its own qualification file records (#61)", {
  strPath <- testthat::test_path(
    "..", "..", "design", "death-count-qualification.md"
  )
  skip_if_not(
    file.exists(strPath),
    "design/ is .Rbuildignore'd and unavailable in this check context"
  )
  chrLines <- readLines(strPath, warn = FALSE)
  chrRow <- grep("^[|] AA-AA-000-0000 [|] Study [|]", chrLines, value = TRUE)
  expect_length(chrRow, 1L)

  chrCells <- trimws(strsplit(chrRow, "|", fixed = TRUE)[[1]])
  chrCells <- chrCells[nzchar(chrCells)]
  expect_equal(as.numeric(chrCells[3]), RECORDED_REPORT$Published$saf0004)
  expect_equal(as.numeric(chrCells[4]), RECORDED_REPORT$Enrolled)
})
