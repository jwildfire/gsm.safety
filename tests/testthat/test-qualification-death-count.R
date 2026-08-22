# Qualifying the death count (#56, D0023).
#
# Passing tests are not the check. A test asserting that the code does what the
# code does would not have caught one of the defects this metric exists to fix.
# The count is therefore measured twice on the same study, by two routes that
# share no code:
#
#   Route B  the death records read directly out of the bundled study with base
#            R — no mapping package, no metric, no gsm helper.
#   Route A  the standard mapping into gsm.mapping's Mapped_Death, then the
#            saf0004 workflow end to end.
#
# Two kinds of assertion live here, and the difference matters. The identities
# between the two routes hold on any version of the bundled study and are
# always checked. The exact counts are a snapshot of one study at one version,
# and gsm.safety tracks gsm.core's main branch, whose bundled study has already
# moved once: between gsm.core 1.2.0 and 1.3.1 the enrolled population went
# from 760 to 762 and the discontinuation-reason deaths from 1 to 4. So the
# snapshot is pinned to the version it was measured against, and a different
# version skips it with both numbers named rather than asserting a stale one.
#
# The recorded result and the reproducer are in
# inst/qualification/death-count-qualification.md and
# tools/qualify-death-count.R. The record is installed content, so the checks
# at the bottom of this file - the record against the code - run under
# R CMD check as well as under devtools::test() (#63).

# Measured 2026-08-21 against gsm.core 1.3.1 and gsm.mapping 1.1.6.
RECORDED <- list(
  gsm.core = "1.3.1",
  StudyID = "AA-AA-000-0000",
  Subjects = 1000L, # every participant in Raw_SUBJ, enrolled or not
  Enrolled = 762L,
  DeathDomain = 12L, # distinct participants with a death record
  Discontinuation = 4L, # distinct participants whose compreas is "Death"
  UnionAll = 16L, # the two sources combined, before the enrolment anchor
  UnionEnrolled = 13L, # the same union, restricted to enrolled participants
  NotEnrolled = c("S42425", "S97688", "S78705")
)

RouteB <- function() {
  # Deliberately base R. The point of a second route is that it shares no
  # implementation with the one being checked.
  lSource <- gsm.core::lSource
  dfSubjects <- lSource$Raw_SUBJ
  chrEnrolled <- unique(as.character(dfSubjects$subjid[dfSubjects$enrollyn == "Y"]))

  dfDeath <- lSource$Raw_Death
  chrDeathDomain <- unique(as.character(dfDeath$subjid[!is.na(dfDeath$death_dt)]))

  dfComp <- lSource$Raw_STUDCOMP
  chrDiscontinuation <- unique(as.character(
    dfComp$subjid[!is.na(dfComp$compreas) & dfComp$compreas == "Death"]
  ))

  chrUnion <- union(chrDeathDomain, chrDiscontinuation)
  list(
    StudyID = unique(as.character(dfSubjects$studyid)),
    Subjects = unique(as.character(dfSubjects$subjid)),
    Enrolled = chrEnrolled,
    DeathDomain = chrDeathDomain,
    Discontinuation = chrDiscontinuation,
    Union = chrUnion,
    UnionEnrolled = intersect(chrUnion, chrEnrolled),
    NotEnrolled = setdiff(chrUnion, chrEnrolled)
  )
}

SkipUnlessRecordedVersion <- function(l) {
  strInstalled <- as.character(utils::packageVersion("gsm.core"))
  if (identical(strInstalled, RECORDED$gsm.core)) {
    return(invisible(TRUE))
  }
  # Never a bare skip: the reason carries the live numbers, so a study that
  # moved cannot pass unseen.
  testthat::skip(paste0(
    "Bundled study snapshot not re-qualified. Recorded against gsm.core ",
    RECORDED$gsm.core, ": ", RECORDED$UnionEnrolled, " deaths of ",
    RECORDED$Enrolled, " enrolled. Installed gsm.core ", strInstalled,
    " reports ", length(l$UnionEnrolled), " of ", length(l$Enrolled),
    ". Re-run tools/qualify-death-count.R and update ",
    "inst/qualification/death-count-qualification.md and this file."
  ))
}

test_that("route B: the two death sources read directly hold together (#56)", {
  l <- RouteB()

  # True of any study, and each one is a property the count depends on.
  expect_gt(length(l$Enrolled), 0L)
  expect_identical(
    length(l$Union),
    length(l$DeathDomain) + length(l$Discontinuation) -
      length(intersect(l$DeathDomain, l$Discontinuation))
  )
  expect_true(all(l$UnionEnrolled %in% l$Enrolled))
  expect_identical(
    sort(l$UnionEnrolled),
    sort(setdiff(l$Union, l$NotEnrolled))
  )
  expect_lte(length(l$UnionEnrolled), length(l$Union))
  # SafetyCensus() reports four on this study, not the one recorded here
  # before 2026-08-21 (see inst/qualification/census-metrics-qualification.md).
  # Whatever
  # the study, the correction this metric exists to make has to be larger than
  # the single participant the pre-1.3.1 study gave that reason to.
  expect_gt(length(l$UnionEnrolled), 1L)
})

test_that("route B: the recorded snapshot of the bundled study (#56)", {
  l <- RouteB()
  SkipUnlessRecordedVersion(l)

  # The study and its size are recorded too, because the qualification record
  # names both and nothing else measures them.
  expect_identical(l$StudyID, RECORDED$StudyID)
  expect_identical(length(l$Subjects), RECORDED$Subjects)
  expect_identical(length(l$Enrolled), RECORDED$Enrolled)
  expect_identical(length(l$DeathDomain), RECORDED$DeathDomain)
  expect_identical(length(l$Discontinuation), RECORDED$Discontinuation)
  # The two sources name entirely different participants on this study, which
  # is why the union is their sum rather than the larger of them.
  expect_identical(length(intersect(l$DeathDomain, l$Discontinuation)), 0L)
  expect_identical(length(l$Union), RECORDED$UnionAll)

  # The finding this qualification turned up: three of the sixteen have a death
  # record or a death discontinuation reason but enrollyn == "N", so the
  # standard mapping's enrolled population — every gsm metric's denominator —
  # does not contain them, and the published count is thirteen.
  expect_identical(length(l$UnionEnrolled), RECORDED$UnionEnrolled)
  expect_setequal(l$NotEnrolled, RECORDED$NotEnrolled)
})

RouteA <- function() {
  lWorkflows <- gsm.core::MakeWorkflowList(
    strNames = c("SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death"),
    strPackage = "gsm.mapping"
  )
  lMapped <- suppressWarnings(suppressMessages({
    lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
    gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(gsm.core::lSource, lSpec))
  }))
  lResult <- suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
    yaml::read_yaml(system.file(
      "workflow", "2_metrics", "saf0004.yaml",
      package = "gsm.safety"
    )),
    lData = lMapped
  )))
  list(Mapped = lMapped, Summary = lResult$Analysis_Summary)
}

test_that("route A: the saf0004 workflow agrees with the records (#56)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")

  lB <- RouteB()
  lA <- RouteA()
  dfSummary <- lA$Summary

  # gsm.mapping's own union, before any metric touches it, reproduced from the
  # raw records by a route that never calls gsm.mapping.
  dfDeath <- lA$Mapped$Mapped_Death
  expect_identical(
    length(unique(dfDeath$subjid[!is.na(dfDeath$death) & dfDeath$death])),
    length(lB$Union)
  )
  expect_identical(nrow(lA$Mapped$Mapped_SUBJ), length(lB$Enrolled))

  expect_identical(nrow(dfSummary), 1L)
  expect_identical(dfSummary$GroupLevel, "Study")
  expect_true(is.na(dfSummary$Flag))

  # The check itself: the two routes, on the same study, land on the same
  # number, and it is the union anchored to the enrolled population.
  expect_identical(dfSummary$Numerator, as.numeric(length(lB$UnionEnrolled)))
  expect_identical(dfSummary$Denominator, as.numeric(length(lB$Enrolled)))
  expect_lte(dfSummary$Numerator, dfSummary$Denominator)
  # And the number the function reports today is the one being replaced: four
  # on gsm.core 1.3.1, one on 1.2.0, so the version-invariant floor is one.
  expect_gt(dfSummary$Numerator, 1)
})

test_that("route A: the recorded snapshot of the published row (#56)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")
  SkipUnlessRecordedVersion(RouteB())

  dfSummary <- RouteA()$Summary

  expect_identical(dfSummary$Numerator, as.numeric(RECORDED$UnionEnrolled))
  expect_identical(dfSummary$Denominator, as.numeric(RECORDED$Enrolled))
})

# ---- The record against the code (#63) --------------------------------------
#
# Everything above measures the study. What follows measures the document:
# every figure in inst/qualification/death-count-qualification.md against the
# constants the tests above assert against the pipeline. Until #63 this record
# had no such layer, and it carried a wrong figure for a day - caught by a
# person reading it, not by a test.
#
# These checks are deliberately not version-pinned. The record and the
# constants are one statement made twice; they have to agree on whatever study
# is installed, and a re-qualification that updates one and not the other is
# exactly what this catches.

STR_DEATH_RECORD <- "death-count-qualification.md"

test_that("the record's measured figures are the qualified figures (#63)", {
  chrLines <- QualificationRecord(STR_DEATH_RECORD)
  lTable <- QualificationTable(
    chrLines, "^[|] Figure [|] Count [|]", STR_DEATH_RECORD
  )

  lExpected <- list(
    "^Participants in" = RECORDED$Subjects,
    "^Enrolled [(]" = RECORDED$Enrolled,
    "^Death domain [(]" = RECORDED$DeathDomain,
    "^Discontinuation reason" = RECORDED$Discontinuation,
    # The union is the sum of the two sources only because they name nobody in
    # common, so the record's overlap row is the arithmetic, not a constant.
    "^Named by both sources" =
      RECORDED$DeathDomain + RECORDED$Discontinuation - RECORDED$UnionAll,
    "^Union, all participants" = RECORDED$UnionAll,
    "^[*][*]Union, enrolled" = RECORDED$UnionEnrolled,
    "^In the union but never enrolled" =
      RECORDED$UnionAll - RECORDED$UnionEnrolled
  )

  for (strPattern in names(lExpected)) {
    chrCells <- QualificationRow(
      lTable, strPattern, STR_DEATH_RECORD, strPattern
    )
    if (length(chrCells) < 2L) next
    ExpectRecordFigure(
      STR_DEATH_RECORD, chrCells[[1]],
      QualificationNumber(chrCells[[2]]), lExpected[[strPattern]]
    )
  }

  # The three excluded participants are named in the record, not just counted.
  chrCells <- QualificationRow(
    lTable, "^In the union but never enrolled", STR_DEATH_RECORD,
    "the participants who were never enrolled"
  )
  if (length(chrCells) >= 2L) {
    expect_setequal(
      regmatches(chrCells[[2]], gregexpr("S[0-9]+", chrCells[[2]]))[[1]],
      RECORDED$NotEnrolled
    )
  }

  RecordDocumentAgreement(STR_DEATH_RECORD, length(lExpected) + 1L)
})

test_that("the record's published row is the row the metric publishes (#63)", {
  chrLines <- QualificationRecord(STR_DEATH_RECORD)
  lTable <- QualificationTable(
    chrLines, "^[|] GroupID [|] GroupLevel [|] Numerator [|]", STR_DEATH_RECORD
  )
  chrCells <- QualificationRow(
    lTable, paste0("^", RECORDED$StudyID), STR_DEATH_RECORD,
    "the published row"
  )
  expect_gte(length(chrCells), 7L)
  if (length(chrCells) >= 7L) {
    expect_identical(chrCells[[2]], "Study")
    ExpectRecordFigure(
      STR_DEATH_RECORD, "the published numerator",
      QualificationNumber(chrCells[[3]]), RECORDED$UnionEnrolled
    )
    ExpectRecordFigure(
      STR_DEATH_RECORD, "the published denominator",
      QualificationNumber(chrCells[[4]]), RECORDED$Enrolled
    )
    # The record rounds the rate, so the comparison is to the digits it prints.
    ExpectRecordFigure(
      STR_DEATH_RECORD, "the published metric",
      QualificationNumber(chrCells[[5]]),
      RECORDED$UnionEnrolled / RECORDED$Enrolled,
      tolerance = 1e-4
    )
    ExpectRecordFigure(
      STR_DEATH_RECORD, "the published score",
      QualificationNumber(chrCells[[6]]), RECORDED$UnionEnrolled
    )
    # Empty is not zero: this metric does not flag.
    expect_match(chrCells[[7]], "empty")
  }

  RecordDocumentAgreement(STR_DEATH_RECORD, 5L)
})

test_that("the record's version table is pinned to the version recorded (#63)", {
  chrLines <- QualificationRecord(STR_DEATH_RECORD)
  strHeader <- "^[|] Figure [|] gsm[.]core "
  lTable <- QualificationTable(chrLines, strHeader, STR_DEATH_RECORD)

  # The right-hand column has to be the version the constants were measured on,
  # or the table below it is describing a study nothing here checks.
  chrHeader <- QualificationCells(grep(strHeader, chrLines, value = TRUE)[[1]])
  expect_match(
    chrHeader[[length(chrHeader)]], RECORDED$gsm.core,
    fixed = TRUE,
    info = paste0(STR_DEATH_RECORD, " pins its version table to the record")
  )

  lExpected <- list(
    "^Enrolled$" = RECORDED$Enrolled,
    "^Death domain$" = RECORDED$DeathDomain,
    "^Discontinuation reason" = RECORDED$Discontinuation,
    "^Union, all$" = RECORDED$UnionAll,
    "^Union, enrolled" = RECORDED$UnionEnrolled
  )
  for (strPattern in names(lExpected)) {
    chrCells <- QualificationRow(
      lTable, strPattern, STR_DEATH_RECORD, strPattern
    )
    if (length(chrCells) < 3L) next
    ExpectRecordFigure(
      STR_DEATH_RECORD, paste(chrCells[[1]], "on gsm.core", RECORDED$gsm.core),
      QualificationNumber(chrCells[[length(chrCells)]]), lExpected[[strPattern]]
    )
  }

  RecordDocumentAgreement(STR_DEATH_RECORD, length(lExpected) + 1L)
})

test_that("the two records agree on the correction this metric makes (#63)", {
  # This is the figure that went wrong. For a day this record said
  # SafetyCensus() reports one death on this study; the function reports four,
  # which census-metrics-qualification.md measures against the live function.
  # Neither record checked the other, so the disagreement sat there until a
  # person read it. Now it fails.
  strCensus <- "census-metrics-qualification.md"
  lMoves <- QualificationTable(
    QualificationRecord(strCensus), "^[|] Figure [|] From [|] To [|]", strCensus
  )
  chrDeaths <- QualificationRow(lMoves, "^Deaths$", strCensus, "the deaths row")
  expect_gte(length(chrDeaths), 3L)
  if (length(chrDeaths) < 3L) {
    return(invisible(NULL))
  }

  nFrom <- QualificationNumber(chrDeaths[[2]])
  nTo <- QualificationNumber(chrDeaths[[3]])
  ExpectRecordFigure(
    strCensus, "the count this metric corrects to", nTo, RECORDED$UnionEnrolled
  )

  # The same pair, stated in prose in both records. Prose is where the wrong
  # figure lived, so prose is checked.
  for (strFile in c(STR_DEATH_RECORD, strCensus)) {
    strProse <- QualificationProse(QualificationRecord(strFile))
    chrPair <- regmatches(strProse, regexec(
      "correction [a-z ]*metric makes is [^0-9]*([0-9]+)[^0-9]+([0-9]+)",
      strProse
    ))[[1]]
    expect_length(chrPair, 3L)
    if (length(chrPair) != 3L) next
    ExpectRecordFigure(
      strFile, "what SafetyCensus() reports today",
      as.numeric(chrPair[[2]]), nFrom
    )
    ExpectRecordFigure(
      strFile, "what this metric corrects it to",
      as.numeric(chrPair[[3]]), nTo
    )
  }

  RecordDocumentAgreement(STR_DEATH_RECORD, 5L)
})
