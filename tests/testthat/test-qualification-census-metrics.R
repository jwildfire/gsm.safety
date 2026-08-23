# Qualifying the eleven census metrics (#58, D0023).
#
# Passing tests are not the check. A test asserting that the code does what the
# code does would not have caught any of the defects this rebuild exists to
# fix. Every figure is therefore measured twice on the same study, by two
# routes that share no code:
#
#   Route B  the study's records read directly out of gsm.core::lSource with
#            base R — no mapping package, no metric, no gsm helper.
#   Route A  the standard gsm.mapping mapping, then each saf00** workflow end
#            to end.
#
# Two kinds of assertion live here. The identities between the two routes hold
# on any version of the bundled study and are always checked. The exact counts
# are a snapshot of one study at one version, and gsm.safety tracks gsm.core's
# main branch, whose bundled study has already moved once — so the snapshot is
# pinned to the version it was measured against, and a different version skips
# it with both numbers named rather than asserting a stale one.
#
# The recorded result and the reproducer are in
# inst/qualification/census-metrics-qualification.md and
# tools/qualify-census-metrics.R. The record is installed content, so the
# checks at the bottom of this file - the record against the code - run under
# R CMD check as well as under devtools::test() (#63).

# Measured 2026-08-21 against gsm.core 1.3.1 and gsm.mapping 1.1.6.
RECORDED_CENSUS <- list(
  gsm.core = "1.3.1",
  Enrolled = 762,
  saf0005 = 762, # enrolled participants
  saf0006 = 577, # randomised participants
  saf0007 = 762, # participants dosed
  saf0008 = 26754, # participant-days on study
  saf0009 = 10761, # participant-days on treatment
  saf0010 = 598, # participants with a lab result
  saf0012 = 661, # participants with a reported AE
  saf0013 = 76, # participants with a disposition record
  saf0014 = 19, # participants who completed
  saf0015 = 9, # participants who discontinued
  # What SafetyCensus() reported before v1.3.0, measured rather than quoted:
  # these are the figures the release notes say move. They cannot be measured
  # any more - #66 removed the arithmetic that produced them - so they live
  # here as recorded history, checked against the record and nothing else.
  CensusDosed = 744,
  CensusDisposition = 100,
  CensusRandomised = NA_real_,
  CensusDeaths = 4
)

CHR_QUALIFIED <- c(
  "saf0005", "saf0006", "saf0007", "saf0008", "saf0009",
  "saf0010", "saf0012", "saf0013", "saf0014", "saf0015"
)

# ---- Route B: the records, read directly ------------------------------------
RouteB_Census <- function() {
  # Deliberately base R. The point of a second route is that it shares no
  # implementation with the one being checked.
  lSource <- gsm.core::lSource
  dfSubjects <- lSource$Raw_SUBJ
  bEnrolled <- !is.na(dfSubjects$enrollyn) & dfSubjects$enrollyn == "Y"
  chrEnrolled <- unique(as.character(dfSubjects$subjid[bEnrolled]))
  dfEnrolled <- dfSubjects[
    bEnrolled & !duplicated(as.character(dfSubjects$subjid)), ,
    drop = FALSE
  ]

  InDomain <- function(df, bKeep = NULL) {
    chrID <- as.character(df$subjid)
    if (!is.null(bKeep)) chrID <- chrID[bKeep]
    length(intersect(unique(chrID), chrEnrolled))
  }

  dfComp <- lSource$Raw_STUDCOMP
  chrCompYN <- toupper(trimws(as.character(dfComp$compyn)))
  dfRand <- lSource$Raw_Randomization
  bRandomised <- !is.na(dfRand$subjid) &
    (is.na(dfRand$status) | dfRand$status != "Screen Failed")

  nOnStudy <- as.numeric(dfEnrolled$timeonstudy)
  nOnTreatment <- as.numeric(dfEnrolled$timeontreatment)
  Total <- function(n) sum(n[is.finite(n) & n >= 0])

  list(
    Enrolled = length(chrEnrolled),
    RawEG = lSource$Raw_EG,
    DispositionRows = length(unique(as.character(dfComp$subjid))),
    OnTreatmentPositive = sum(nOnTreatment > 0, na.rm = TRUE),
    saf0005 = length(chrEnrolled),
    saf0006 = InDomain(dfRand, bRandomised),
    saf0007 = length(unique(as.character(
      dfEnrolled$subjid[!is.na(dfEnrolled$firstdosedate)]
    ))),
    saf0008 = Total(nOnStudy),
    saf0009 = Total(nOnTreatment),
    saf0010 = InDomain(lSource$Raw_LB),
    saf0012 = InDomain(lSource$Raw_AE),
    saf0013 = InDomain(dfComp),
    saf0014 = InDomain(dfComp, chrCompYN %in% "Y"),
    saf0015 = InDomain(dfComp, chrCompYN %in% "N")
  )
}

# ---- Route A: the standard mapping, then each metric ------------------------
RouteA_Census <- function() {
  # suppressWarnings: gsm.core 1.3.0 deprecated MakeWorkflowList() and
  # RunWorkflow() in favour of workr's. gsm.safety does not depend on workr, so
  # the package keeps calling gsm.core's re-exports until that move is its own
  # piece of work.
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
  lSummary <- lapply(CHR_QUALIFIED, function(strID) {
    suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
      yaml::read_yaml(system.file(
        "workflow", "2_metrics", paste0(strID, ".yaml"),
        package = "gsm.safety"
      )),
      lData = lMapped
    )))$Analysis_Summary
  })
  list(Mapped = lMapped, Summary = stats::setNames(lSummary, CHR_QUALIFIED))
}

SkipUnlessRecordedCensus <- function(lB) {
  strInstalled <- as.character(utils::packageVersion("gsm.core"))
  if (identical(strInstalled, RECORDED_CENSUS$gsm.core)) {
    return(invisible(TRUE))
  }
  # Never a bare skip: the reason carries the live numbers, so a study that
  # moved cannot pass unseen.
  testthat::skip(paste0(
    "Bundled study snapshot not re-qualified. Recorded against gsm.core ",
    RECORDED_CENSUS$gsm.core, ": ", RECORDED_CENSUS$Enrolled,
    " enrolled, ", RECORDED_CENSUS$saf0006, " randomised, ",
    RECORDED_CENSUS$saf0013, " with a disposition record. Installed gsm.core ",
    strInstalled, " reports ", lB$Enrolled, ", ", lB$saf0006, " and ",
    lB$saf0013, ". Re-run tools/qualify-census-metrics.R and update ",
    "inst/qualification/census-metrics-qualification.md and this file."
  ))
}

test_that("route B: the records read directly hold together (#58)", {
  lB <- RouteB_Census()

  # True of any study, and each one is a property a census figure depends on.
  expect_gt(lB$Enrolled, 0)
  for (strID in setdiff(CHR_QUALIFIED, c("saf0008", "saf0009"))) {
    expect_lte(lB[[strID]], lB$Enrolled, label = strID)
    expect_gte(lB[[strID]], 0, label = strID)
  }
  expect_identical(lB$saf0005, lB$Enrolled)
  # Completed and discontinued are two values of one recorded flag, so neither
  # alone, nor both together, can exceed the participants who have the record.
  expect_lte(lB$saf0014 + lB$saf0015, lB$saf0013)
  # Anchoring is the whole point: the disposition domain names participants the
  # study never enrolled, and they cannot be counted.
  expect_lte(lB$saf0013, lB$DispositionRows)
  expect_gte(lB$saf0008, lB$saf0009) # nobody is on treatment longer than on study
})

test_that("route B: the recorded snapshot of the bundled study (#58)", {
  lB <- RouteB_Census()
  SkipUnlessRecordedCensus(lB)

  for (strID in CHR_QUALIFIED) {
    expect_identical(
      as.numeric(lB[[strID]]), as.numeric(RECORDED_CENSUS[[strID]]),
      label = strID
    )
  }
  expect_identical(as.numeric(lB$Enrolled), RECORDED_CENSUS$Enrolled)
  expect_identical(as.numeric(lB$DispositionRows), RECORDED_CENSUS$CensusDisposition)
  expect_identical(as.numeric(lB$OnTreatmentPositive), RECORDED_CENSUS$CensusDosed)
})

test_that("route A: every census metric agrees with the records (#58)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")

  lB <- RouteB_Census()
  lA <- RouteA_Census()

  expect_identical(nrow(lA$Mapped$Mapped_SUBJ), as.integer(lB$Enrolled))

  for (strID in CHR_QUALIFIED) {
    dfSummary <- lA$Summary[[strID]]

    expect_identical(nrow(dfSummary), 1L, label = strID)
    expect_identical(dfSummary$GroupLevel, "Study", label = strID)
    expect_true(is.na(dfSummary$Flag), label = strID)
    expect_identical(dfSummary$Score, dfSummary$Numerator, label = strID)

    # The check itself: the two routes, on the same study, land on the same
    # number, by implementations that share nothing.
    expect_identical(dfSummary$Numerator, as.numeric(lB[[strID]]), label = strID)
    expect_identical(
      dfSummary$Denominator, as.numeric(lB$Enrolled),
      label = strID
    )
    if (!strID %in% c("saf0008", "saf0009")) {
      expect_lte(dfSummary$Numerator, dfSummary$Denominator, label = strID)
    }
  }
})

test_that("route A: the recorded snapshot of the published rows (#58)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")
  SkipUnlessRecordedCensus(RouteB_Census())

  lA <- RouteA_Census()
  for (strID in CHR_QUALIFIED) {
    expect_identical(
      lA$Summary[[strID]]$Numerator, as.numeric(RECORDED_CENSUS[[strID]]),
      label = strID
    )
    expect_identical(
      lA$Summary[[strID]]$Denominator, RECORDED_CENSUS$Enrolled,
      label = strID
    )
  }
})

test_that("saf0011 has no second route on this study, and stops rather than reporting zero (#58)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")

  lB <- RouteB_Census()
  # If a bundled ECG domain ever appears, this metric becomes qualifiable and
  # this test has to be replaced by a measurement rather than left passing.
  expect_null(lB$RawEG)

  lA <- RouteA_Census()
  expect_false("Mapped_EG" %in% names(lA$Mapped))
  expect_error(suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
    yaml::read_yaml(system.file(
      "workflow", "2_metrics", "saf0011.yaml",
      package = "gsm.safety"
    )),
    lData = lA$Mapped
  ))))
})

test_that("the figures the record says move have moved (#58, #66)", {
  # The "before" figures are history now: step four (#66) removed the
  # arithmetic that produced them, so they cannot be re-measured here. They are
  # asserted as recorded figures in the document-agreement block below, and the
  # record marks that column as pre-v1.3.0 rather than "today".
  #
  # What can be measured is the other half of every row in the record's table
  # of what moves: the figure the function reports now.
  skip_if_not_installed("gsm.mapping")
  lB <- RouteB_Census()
  SkipUnlessRecordedCensus(lB)

  lA <- RouteA_Census()
  lCensus <- suppressWarnings(suppressMessages(SafetyCensus(
    dfSubjects = lA$Mapped$Mapped_SUBJ,
    dfLabs = lA$Mapped$Mapped_LB,
    dfAE = lA$Mapped$Mapped_AE,
    dfDisposition = lA$Mapped$Mapped_STUDCOMP,
    dfDeath = lA$Mapped$Mapped_Death,
    dfRandomization = lA$Mapped$Mapped_Randomization
  )))
  Figure <- function(strLabel) {
    lCensus$Census$Value[lCensus$Census$Label == strLabel]
  }

  expect_identical(Figure("Received study drug"), RECORDED_CENSUS$saf0007)
  expect_identical(
    Figure("Participants with a disposition record"), RECORDED_CENSUS$saf0013
  )
  expect_identical(Figure("Randomised to an arm"), RECORDED_CENSUS$saf0006)
  # The death count is qualified against its own record, so the payload's
  # figure is compared with it there rather than restated here.
  # Reported blank where the domain is missing was the fifth defect in the
  # record's table; absent is NA and never a zero.
  expect_true(is.na(Figure("Participants with an ECG")))
  # And the figures that were already right are unmoved.
  expect_identical(Figure("Enrolled participants"), RECORDED_CENSUS$Enrolled)
  expect_identical(
    Figure("Participants with a lab result"), as.numeric(lB$saf0010)
  )
})

# ---- The record against the code (#63) --------------------------------------
#
# Everything above measures the study. What follows measures the document:
# every figure in inst/qualification/census-metrics-qualification.md against
# the constants the tests above assert against the pipeline. Until #63 this
# record had no such layer at all, so a figure re-measured in one place and not
# the other stayed green indefinitely.
#
# These checks are deliberately not version-pinned. The record and the
# constants are one statement made twice; they have to agree on whatever study
# is installed, and a re-qualification that updates one and not the other is
# exactly what this catches.

STR_CENSUS_RECORD <- "census-metrics-qualification.md"

CensusRecordTable <- function() {
  QualificationTable(
    QualificationRecord(STR_CENSUS_RECORD),
    "^[|] Metric [|] Figure [|] Route A [|] Route B [|]", STR_CENSUS_RECORD
  )
}

test_that("the record's two routes are the qualified figures (#63)", {
  lTable <- CensusRecordTable()
  nChecked <- 0L

  for (strID in CHR_QUALIFIED) {
    chrCells <- QualificationRow(
      lTable, paste0("^`", strID, "`$"), STR_CENSUS_RECORD, strID
    )
    if (length(chrCells) < 4L) next
    # Metric | Figure | Route A | Route B | `SafetyCensus()` today
    ExpectRecordFigure(
      STR_CENSUS_RECORD, paste(strID, "route A"),
      QualificationNumber(chrCells[[3]]), RECORDED_CENSUS[[strID]]
    )
    # The two routes agreed when the record was written; if that ever stops
    # being true in the record itself, this says so.
    ExpectRecordFigure(
      STR_CENSUS_RECORD, paste(strID, "route B"),
      QualificationNumber(chrCells[[4]]), RECORDED_CENSUS[[strID]]
    )
    nChecked <- nChecked + 2L
  }

  # The metric with no domain on any study today has no figure on either
  # route, and the record has to say so rather than carrying a number.
  chrCells <- QualificationRow(
    lTable, "^`saf0011`$", STR_CENSUS_RECORD, "saf0011"
  )
  if (length(chrCells) >= 4L) {
    expect_true(is.na(QualificationNumber(chrCells[[3]])))
    expect_true(is.na(QualificationNumber(chrCells[[4]])))
    nChecked <- nChecked + 2L
  }

  # The anchor every figure in the record is counted against.
  strProse <- QualificationProse(QualificationRecord(STR_CENSUS_RECORD))
  chrAnchor <- regmatches(strProse, regexec(
    "anchor for every figure below is the enrolled population: [*]{2}([0-9,]+)",
    strProse
  ))[[1]]
  expect_length(chrAnchor, 2L)
  if (length(chrAnchor) == 2L) {
    ExpectRecordFigure(
      STR_CENSUS_RECORD, "the enrolled anchor",
      QualificationNumber(chrAnchor[[2]]), RECORDED_CENSUS$Enrolled
    )
    nChecked <- nChecked + 1L
  }

  RecordDocumentAgreement(STR_CENSUS_RECORD, nChecked)
})

test_that("the record's SafetyCensus() column is what the function reports (#63)", {
  # Only the cells that state a count are compared here. The two person-time
  # cells are person-years, and they are checked against the report's own
  # division in test-qualification-census-report.R, where the workflow's
  # DaysPerYear setting is already loaded; the two disposition cells say
  # "inside a table" rather than a figure.
  lTable <- CensusRecordTable()
  lToday <- list(
    saf0005 = RECORDED_CENSUS$Enrolled,
    saf0006 = RECORDED_CENSUS$CensusRandomised, # NA: the function reports blank
    saf0007 = RECORDED_CENSUS$CensusDosed,
    saf0010 = RECORDED_CENSUS$saf0010,
    saf0012 = RECORDED_CENSUS$saf0012,
    saf0013 = RECORDED_CENSUS$CensusDisposition
  )

  for (strID in names(lToday)) {
    chrCells <- QualificationRow(
      lTable, paste0("^`", strID, "`$"), STR_CENSUS_RECORD, strID
    )
    if (length(chrCells) < 5L) next
    ExpectRecordFigure(
      STR_CENSUS_RECORD, paste(strID, "as SafetyCensus() reports it today"),
      QualificationNumber(chrCells[[5]]), lToday[[strID]]
    )
  }

  RecordDocumentAgreement(STR_CENSUS_RECORD, length(lToday))
})

test_that("the record's table of what moves is what the metrics publish (#63)", {
  # From is what SafetyCensus() reports today, measured above; To is what the
  # metric publishes, qualified above. The deaths row is checked in
  # test-qualification-death-count.R, against that metric's own record.
  lTable <- QualificationTable(
    QualificationRecord(STR_CENSUS_RECORD),
    "^[|] Figure [|] From [|] To [|]", STR_CENSUS_RECORD
  )
  lMoves <- list(
    "^Randomised to an arm" = list(
      From = RECORDED_CENSUS$CensusRandomised, To = RECORDED_CENSUS$saf0006
    ),
    "^Received study drug" = list(
      From = RECORDED_CENSUS$CensusDosed, To = RECORDED_CENSUS$saf0007
    ),
    "^Participants with a disposition record" = list(
      From = RECORDED_CENSUS$CensusDisposition, To = RECORDED_CENSUS$saf0013
    )
  )

  for (strPattern in names(lMoves)) {
    chrCells <- QualificationRow(
      lTable, strPattern, STR_CENSUS_RECORD, strPattern
    )
    if (length(chrCells) < 3L) next
    ExpectRecordFigure(
      STR_CENSUS_RECORD, paste(chrCells[[1]], "before this release"),
      QualificationNumber(chrCells[[2]]), lMoves[[strPattern]]$From
    )
    ExpectRecordFigure(
      STR_CENSUS_RECORD, paste(chrCells[[1]], "after this release"),
      QualificationNumber(chrCells[[3]]), lMoves[[strPattern]]$To
    )
  }

  RecordDocumentAgreement(STR_CENSUS_RECORD, 2L * length(lMoves))
})
