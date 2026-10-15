DeathWorkflow <- function() {
  strPath <- system.file(
    "workflow", "2_metrics", "saf0004.yaml",
    package = "gsm.safety"
  )
  # Never skip on a missing definition: the yaml IS the deliverable, and a
  # skipped test reads as a passing one.
  if (!nzchar(strPath)) stop("no workflow yaml for saf0004")
  yaml::read_yaml(strPath)
}

RunDeath <- function(lData) {
  suppressWarnings(suppressMessages(
    gsm.core::RunWorkflow(DeathWorkflow(), lData = lData)
  ))
}

DEATH_DATA <- function() {
  list(
    Mapped_SUBJ = data.frame(
      subjid = c("S1", "S2", "S3", "S4"),
      studyid = "AA-AA-000-0000",
      stringsAsFactors = FALSE
    ),
    Mapped_Death = data.frame(
      subjid = c("S1", "S2", "S3"),
      # NA is what gsm.mapping::complete_death() leaves on the rows it carries
      # for progressive disease rather than death.
      death = c(TRUE, TRUE, NA),
      stringsAsFactors = FALSE
    )
  )
}

test_that("the death metric declares no threshold and calls no flagging step (#56)", {
  # D0023.3: no census number raises anything. The property is proven by what
  # the definition does not contain.
  lWorkflow <- DeathWorkflow()
  lMeta <- lWorkflow$meta

  expect_null(lMeta$Threshold)
  expect_null(lMeta$Flag)
  expect_null(lMeta$RiskScoreWeight)
  expect_false(isTRUE(lMeta$GenerateRiskSignal))

  chrSteps <- vapply(lWorkflow$steps, function(lStep) lStep$name, character(1))
  expect_false(any(grepl("^gsm[.]core::Flag", chrSteps)))
  expect_true("gsm.safety::Flag_None" %in% chrSteps)
  expect_false(any(grepl("ParseThreshold", chrSteps)))

  # gsm.reporting::MakeMetric() turns meta into one tibble row.
  for (strKey in names(lMeta)) {
    expect_length(lMeta[[strKey]], 1L)
  }
})

test_that("the death metric is a study-level count of enrolled participants (#56)", {
  # D0023.4: study level ships, and the level is a setting from the first line.
  lMeta <- DeathWorkflow()$meta

  expect_identical(lMeta$ID, "saf0004")
  expect_identical(lMeta$Type, "Analysis")
  expect_identical(lMeta$GroupLevel, "Study")
  expect_identical(lMeta$GroupCol, "studyid")
  expect_identical(lMeta$Denominator, "Enrolled Participant")
})

test_that("the death metric runs end to end and its row does not flag (#56)", {
  lResult <- RunDeath(DEATH_DATA())
  dfSummary <- lResult$Analysis_Summary

  expect_identical(
    names(dfSummary),
    c("GroupID", "GroupLevel", "Numerator", "Denominator", "Metric", "Score", "Flag")
  )
  expect_identical(nrow(dfSummary), 1L)
  expect_identical(dfSummary$GroupLevel, "Study")
  expect_identical(dfSummary$GroupID, "AA-AA-000-0000")
  expect_identical(dfSummary$Numerator, 2)
  expect_identical(dfSummary$Denominator, 4)
  expect_identical(dfSummary$Score, dfSummary$Numerator)
  expect_true(is.na(dfSummary$Flag))

  # The unsummarised input stays beside the summary, one row per participant.
  expect_identical(nrow(lResult$Analysis_Input), 4L)
})

test_that("duplicating a death row changes the published count by nothing (#56)", {
  lData <- DEATH_DATA()
  nBefore <- RunDeath(lData)$Analysis_Summary$Numerator

  lData$Mapped_Death <- rbind(lData$Mapped_Death, lData$Mapped_Death[1, , drop = FALSE])
  expect_identical(RunDeath(lData)$Analysis_Summary$Numerator, nBefore)
})

test_that("a participant in the death domain but never enrolled is not counted (#56)", {
  lData <- DEATH_DATA()
  lData$Mapped_Death <- rbind(lData$Mapped_Death, data.frame(
    subjid = "GHOST", death = TRUE, stringsAsFactors = FALSE
  ))
  dfSummary <- RunDeath(lData)$Analysis_Summary

  expect_identical(dfSummary$Numerator, 2)
  expect_lte(dfSummary$Numerator, dfSummary$Denominator)
})

test_that("a study with no death domain errors rather than reporting zero (#56)", {
  lData <- DEATH_DATA()
  lData$Mapped_Death <- NULL

  expect_error(suppressMessages(
    gsm.core::RunWorkflow(DeathWorkflow(), lData = lData)
  ))
})

test_that("a study whose death domain lost the death column errors (#56)", {
  # CheckSpec() only warns on a missing declared column, so the workflow has to
  # stop inside the step. Without this the count would quietly read zero.
  lData <- DEATH_DATA()
  lData$Mapped_Death$death <- NULL

  expect_error(suppressWarnings(suppressMessages(
    gsm.core::RunWorkflow(DeathWorkflow(), lData = lData)
  )), "death")
})

test_that("an empty death domain publishes no row at all (#56)", {
  lData <- DEATH_DATA()
  lData$Mapped_Death <- lData$Mapped_Death[0, , drop = FALSE]
  dfSummary <- RunDeath(lData)$Analysis_Summary

  expect_identical(nrow(dfSummary), 0L)
})

test_that("a study with a populated death domain and no deaths publishes zero (#56)", {
  lData <- DEATH_DATA()
  lData$Mapped_Death$death <- NA
  dfSummary <- RunDeath(lData)$Analysis_Summary

  expect_identical(nrow(dfSummary), 1L)
  expect_identical(dfSummary$Numerator, 0)
  expect_identical(dfSummary$Denominator, 4)
})
