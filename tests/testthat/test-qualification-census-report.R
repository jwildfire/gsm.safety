# Qualifying the census report (#61, D0023). Step three of four.
#
# The report's job is to present figures it did not compute, so qualifying it
# is not "does the code do what the code does" — it is whether the numbers a
# reader sees on the page are the numbers recorded in
# inst/qualification/census-metrics-qualification.md, which were themselves
# measured twice by routes that share no code.
#
# Two directions are checked, because either one alone can rot:
#
#   1. The page against the record. The whole pipeline runs on the bundled
#      study - mapping, the twelve metrics, the reporting model, the report -
#      and every presented figure is compared with the recorded one.
#   2. The record against the qualification records. The constants below are
#      compared with the tables in inst/qualification/, so a figure re-measured
#      in one of those files and not here shows up as a failure rather than as
#      a quiet disagreement between two documents.
#
# Until #63 the records lived in design/, which is .Rbuildignore'd, so
# direction 2 ran under devtools::test() and skipped under R CMD check - the
# context that gates the merge. The records are installed content now and it
# runs everywhere. Direction 1 runs wherever the packages are installed, and is
# pinned to the gsm.core the figures were measured on: the bundled study moved
# once already between 1.2.0 and 1.3.1.

# Measured 2026-08-21 against gsm.core 1.3.1 and gsm.mapping 1.1.6, and
# recorded in inst/qualification/census-metrics-qualification.md.
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
    "inst/qualification/census-metrics-qualification.md."
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


# ---- SafetyCensus(), on the same study (#66) --------------------------------
#
# Step four rewired the function to run the metrics and read them, so its
# figures and the report's figures are now one set of numbers presented twice.
# This is where that is checked rather than assumed: the same pipeline, through
# the caller-facing function, compared with the same record.

# Which metric each label on the payload reads. The labels are a contract
# (D0023.5) and this is the only place the mapping between them and the metric
# IDs is stated in the suite.
CENSUS_PAYLOAD_LABELS <- list(
  saf0005 = "Enrolled participants",
  saf0006 = "Randomised to an arm",
  saf0007 = "Received study drug",
  saf0004 = "Deaths",
  saf0008 = "Person-years on study",
  saf0009 = "Person-years on treatment",
  saf0010 = "Participants with a lab result",
  saf0012 = "Participants with a reported AE",
  saf0013 = "Participants with a disposition record"
)

BundledSafetyCensus <- function() {
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

  suppressWarnings(suppressMessages(SafetyCensus(
    dfSubjects = lMapped$Mapped_SUBJ,
    dfLabs = lMapped$Mapped_LB,
    dfAE = lMapped$Mapped_AE,
    dfDisposition = lMapped$Mapped_STUDCOMP,
    dfDeath = lMapped$Mapped_Death,
    dfRandomization = lMapped$Mapped_Randomization
  )))
}

test_that("SafetyCensus publishes the qualified figures, not its own (#66)", {
  SkipUnlessQualifiedVersion()

  lCensus <- BundledSafetyCensus()
  nChecked <- 0L

  for (strID in names(CENSUS_PAYLOAD_LABELS)) {
    strLabel <- CENSUS_PAYLOAD_LABELS[[strID]]
    nValue <- lCensus$Census$Value[lCensus$Census$Label == strLabel]
    expect_identical(length(nValue), 1L, info = strLabel)

    nExpected <- if (!is.null(RECORDED_REPORT$PersonYears[[strID]])) {
      RECORDED_REPORT$PersonYears[[strID]]
    } else {
      RECORDED_REPORT$Published[[strID]]
    }
    expect_equal(nValue, as.numeric(nExpected), info = strLabel)
    nChecked <- nChecked + 1L
  }

  # The ECG figure has no domain on this study, so it is absent on the payload
  # too - and absent is NA, never a zero.
  nECG <- lCensus$Census$Value[
    lCensus$Census$Label == "Participants with an ECG"
  ]
  expect_identical(length(nECG), 1L)
  expect_true(is.na(nECG))
  nChecked <- nChecked + 1L

  RecordDocumentAgreement("SafetyCensus() on the bundled study", nChecked)
})

test_that("the payload's disposition states are the disposition metrics (#66)", {
  SkipUnlessQualifiedVersion()

  lCensus <- BundledSafetyCensus()
  vState <- stats::setNames(
    lCensus$Disposition$Participants, lCensus$Disposition$State
  )

  expect_equal(vState[["Died"]], as.numeric(RECORDED_REPORT$Published$saf0004))
  expect_equal(
    vState[["Completed"]], as.numeric(RECORDED_REPORT$Published$saf0014)
  )
  expect_equal(
    vState[["Discontinued"]], as.numeric(RECORDED_REPORT$Published$saf0015)
  )

  RecordDocumentAgreement("SafetyCensus() disposition on the bundled study", 3L)
})


# ---- The record against the qualification records (#63) ---------------------
#
# The records are installed content, so these run under R CMD check - where the
# merge is gated - and not only under devtools::test(). They are not
# version-pinned: a record and the constants beside it are one statement made
# twice, and they have to agree on whatever study is installed.

STR_METRICS_RECORD <- "census-metrics-qualification.md"
STR_DEATH_RECORD <- "death-count-qualification.md"
STR_REPORT_RECORD <- "census-report-qualification.md"

CensusMetricsRecordTable <- function() {
  QualificationTable(
    QualificationRecord(STR_METRICS_RECORD),
    "^[|] Metric [|] Figure [|] Route A [|] Route B [|]", STR_METRICS_RECORD
  )
}

test_that("the recorded figures are the ones the qualification record records (#61)", {
  lTable <- CensusMetricsRecordTable()
  nChecked <- 0L

  for (strID in names(RECORDED_REPORT$Published)) {
    if (identical(strID, "saf0004")) next # qualified in the death record
    chrCells <- QualificationRow(
      lTable, paste0("^`", strID, "`$"), STR_METRICS_RECORD, strID
    )
    if (length(chrCells) < 4L) next
    ExpectRecordFigure(
      STR_METRICS_RECORD, paste(strID, "route A"),
      QualificationNumber(chrCells[[3]]), RECORDED_REPORT$Published[[strID]]
    )
    # The two routes agreed when it was recorded; if that ever stops being
    # true in the record, this says so before the report quotes it.
    ExpectRecordFigure(
      STR_METRICS_RECORD, paste(strID, "route B"),
      QualificationNumber(chrCells[[4]]), RECORDED_REPORT$Published[[strID]]
    )
    nChecked <- nChecked + 2L
  }

  # The metric with no second route is recorded as having none.
  chrCells <- QualificationRow(
    lTable, paste0("^`", RECORDED_REPORT$Absent, "`$"), STR_METRICS_RECORD,
    RECORDED_REPORT$Absent
  )
  if (length(chrCells) >= 3L) {
    expect_true(is.na(QualificationNumber(chrCells[[3]])))
    nChecked <- nChecked + 1L
  }

  RecordDocumentAgreement(STR_METRICS_RECORD, nChecked)
})

test_that("the presented person-years are the recorded participant-days divided (#61)", {
  lTable <- CensusMetricsRecordTable()
  lSettings <- CensusReportSettings()

  for (strID in names(RECORDED_REPORT$PersonYears)) {
    chrCells <- QualificationRow(
      lTable, paste0("^`", strID, "`$"), STR_METRICS_RECORD, strID
    )
    if (length(chrCells) < 5L) next
    nDays <- QualificationNumber(chrCells[[3]])
    ExpectRecordFigure(
      STR_METRICS_RECORD, paste(strID, "as person-years"),
      round(nDays / lSettings$PersonTime$DaysPerYear, 1),
      RECORDED_REPORT$PersonYears[[strID]]
    )
    # The same division is what the record says the function presents today.
    ExpectRecordFigure(
      STR_METRICS_RECORD, paste(strID, "as SafetyCensus() presents it today"),
      QualificationNumber(chrCells[[5]]), RECORDED_REPORT$PersonYears[[strID]]
    )
  }

  RecordDocumentAgreement(
    STR_METRICS_RECORD, 2L * length(RECORDED_REPORT$PersonYears)
  )
})

test_that("the death count is the figure its own qualification record records (#61)", {
  lTable <- QualificationTable(
    QualificationRecord(STR_DEATH_RECORD),
    "^[|] GroupID [|] GroupLevel [|] Numerator [|]", STR_DEATH_RECORD
  )
  chrCells <- QualificationRow(
    lTable, paste0("^", RECORDED_REPORT$StudyID), STR_DEATH_RECORD,
    "the published row"
  )
  expect_gte(length(chrCells), 4L)
  if (length(chrCells) >= 4L) {
    ExpectRecordFigure(
      STR_DEATH_RECORD, "the death count",
      QualificationNumber(chrCells[[3]]), RECORDED_REPORT$Published$saf0004
    )
    ExpectRecordFigure(
      STR_DEATH_RECORD, "the enrolled denominator",
      QualificationNumber(chrCells[[4]]), RECORDED_REPORT$Enrolled
    )
  }

  RecordDocumentAgreement(STR_DEATH_RECORD, 2L)
})

test_that("the report's own record is the figures the report presents (#63)", {
  # The report's record had no document-agreement layer either - the file that
  # checks the other two was not checking itself.
  lTable <- QualificationTable(
    QualificationRecord(STR_REPORT_RECORD),
    "^[|] Metric [|] On the page [|] Qualified figure [|]", STR_REPORT_RECORD
  )
  nChecked <- 0L

  for (strID in names(RECORDED_REPORT$Published)) {
    chrCells <- QualificationRow(
      lTable, paste0("^`", strID, "`$"), STR_REPORT_RECORD, strID
    )
    if (length(chrCells) < 4L) next

    nPresented <- if (!is.null(RECORDED_REPORT$PersonYears[[strID]])) {
      RECORDED_REPORT$PersonYears[[strID]]
    } else {
      RECORDED_REPORT$Published[[strID]]
    }
    ExpectRecordFigure(
      STR_REPORT_RECORD, paste(strID, "on the page"),
      QualificationNumber(chrCells[[2]]), nPresented
    )
    # Every figure on the page is presented beside its denominator.
    expect_match(
      chrCells[[2]], paste0("of ", RECORDED_REPORT$Enrolled), fixed = TRUE,
      info = paste0(STR_REPORT_RECORD, " records the denominator for ", strID)
    )
    ExpectRecordFigure(
      STR_REPORT_RECORD, paste(strID, "as qualified"),
      QualificationNumber(chrCells[[3]]), RECORDED_REPORT$Published[[strID]]
    )
    ExpectRecordFigure(
      STR_REPORT_RECORD, paste(strID, "as published by the metric"),
      QualificationNumber(chrCells[[4]]), RECORDED_REPORT$Published[[strID]]
    )
    nChecked <- nChecked + 3L
  }

  # The metric with no domain publishes nothing and the record says so.
  chrCells <- QualificationRow(
    lTable, paste0("^`", RECORDED_REPORT$Absent, "`$"), STR_REPORT_RECORD,
    RECORDED_REPORT$Absent
  )
  if (length(chrCells) >= 4L) {
    expect_true(is.na(QualificationNumber(chrCells[[2]])))
    expect_true(is.na(QualificationNumber(chrCells[[4]])))
    nChecked <- nChecked + 2L
  }

  RecordDocumentAgreement(STR_REPORT_RECORD, nChecked)
})
