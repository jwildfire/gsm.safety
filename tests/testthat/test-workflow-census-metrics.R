# The eleven census metrics of #58, driven from one table rather than eleven
# hand-written blocks. Twelve ports of the same mistake is the failure mode
# this build was warned about, so every rule is asserted the same way for every
# metric and a metric that quietly skipped one would show up as a failure here.

CensusWorkflow <- function(strID) {
  strPath <- system.file(
    "workflow", "2_metrics", paste0(strID, ".yaml"),
    package = "gsm.safety"
  )
  # Never skip on a missing definition: the yaml IS the deliverable, and a
  # skipped test reads as a passing one.
  if (!nzchar(strPath)) stop(paste("no workflow yaml for", strID))
  yaml::read_yaml(strPath)
}

RunCensus <- function(strID, lData) {
  suppressWarnings(suppressMessages(
    gsm.core::RunWorkflow(CensusWorkflow(strID), lData = lData)
  ))
}

CENSUS_DATA <- function() {
  list(
    Mapped_SUBJ = data.frame(
      subjid = c("S1", "S2", "S3", "S4"),
      studyid = "AA-AA-000-0000",
      firstdosedate = as.Date(c("2012-01-01", "2012-01-02", "2012-01-03", NA)),
      timeonstudy = c(10L, 20L, 30L, 40L),
      timeontreatment = c(5L, 0L, 15L, 20L),
      stringsAsFactors = FALSE
    ),
    Mapped_Randomization = data.frame(
      subjid = c("S1", "S2", "S3"), stringsAsFactors = FALSE
    ),
    Mapped_LB = data.frame(
      subjid = c("S1", "S1", "S1", "S2"), stringsAsFactors = FALSE
    ),
    Mapped_EG = data.frame(subjid = c("S1", "S1"), stringsAsFactors = FALSE),
    Mapped_AE = data.frame(
      subjid = c("S1", "S2", "S2", "S3"), stringsAsFactors = FALSE
    ),
    Mapped_STUDCOMP = data.frame(
      subjid = c("S1", "S2", "S3"),
      compyn = c("Y", "N", NA),
      stringsAsFactors = FALSE
    )
  )
}

# id          the metric
# domain      the mapped domain it counts from
# column      a declared column of that domain, dropped to prove the metric
#             stops instead of publishing a zero
# numerator   what it publishes on the fixture above
# ghost       FALSE where the domain IS the enrolled population, so a
#             participant cannot be in one and not the other
LCENSUS <- list(
  list(id = "saf0005", domain = "Mapped_SUBJ", column = "studyid", numerator = 4, ghost = FALSE),
  list(id = "saf0006", domain = "Mapped_Randomization", column = "subjid", numerator = 3, ghost = TRUE),
  list(id = "saf0007", domain = "Mapped_SUBJ", column = "firstdosedate", numerator = 3, ghost = FALSE),
  list(id = "saf0008", domain = "Mapped_SUBJ", column = "timeonstudy", numerator = 100, ghost = FALSE),
  list(id = "saf0009", domain = "Mapped_SUBJ", column = "timeontreatment", numerator = 40, ghost = FALSE),
  list(id = "saf0010", domain = "Mapped_LB", column = "subjid", numerator = 2, ghost = TRUE),
  list(id = "saf0011", domain = "Mapped_EG", column = "subjid", numerator = 1, ghost = TRUE),
  list(id = "saf0012", domain = "Mapped_AE", column = "subjid", numerator = 3, ghost = TRUE),
  list(id = "saf0013", domain = "Mapped_STUDCOMP", column = "subjid", numerator = 3, ghost = TRUE),
  list(id = "saf0014", domain = "Mapped_STUDCOMP", column = "compyn", numerator = 1, ghost = TRUE),
  list(id = "saf0015", domain = "Mapped_STUDCOMP", column = "compyn", numerator = 1, ghost = TRUE)
)

CHR_CENSUS <- vapply(LCENSUS, function(l) l$id, character(1))

test_that("every census metric declares no threshold and calls no flagging step (#58)", {
  # D0023.3: no census number raises anything. The property is proven by what
  # the definition does not contain.
  for (strID in CHR_CENSUS) {
    lWorkflow <- CensusWorkflow(strID)
    lMeta <- lWorkflow$meta

    expect_null(lMeta$Threshold, info = strID)
    expect_null(lMeta$Flag, info = strID)
    expect_null(lMeta$RiskScoreWeight, info = strID)
    expect_false(isTRUE(lMeta$GenerateRiskSignal), info = strID)

    chrSteps <- vapply(lWorkflow$steps, function(lStep) lStep$name, character(1))
    expect_false(any(grepl("^gsm[.]core::Flag", chrSteps)), info = strID)
    expect_true("gsm.safety::Flag_None" %in% chrSteps, info = strID)
    expect_false(any(grepl("ParseThreshold", chrSteps)), info = strID)

    # gsm.reporting::MakeMetric() turns meta into one tibble row.
    for (strKey in names(lMeta)) {
      expect_length(lMeta[[strKey]], 1L)
    }
  }
})

test_that("every census metric is study level, and the level is a setting (#58)", {
  # D0023.4: study level ships, and the level is a setting from the first line.
  for (lMetric in LCENSUS) {
    lMeta <- CensusWorkflow(lMetric$id)$meta

    expect_identical(lMeta$ID, lMetric$id, info = lMetric$id)
    expect_identical(lMeta$Type, "Analysis", info = lMetric$id)
    expect_identical(lMeta$GroupLevel, "Study", info = lMetric$id)
    expect_identical(lMeta$GroupCol, "studyid", info = lMetric$id)
    expect_identical(lMeta$Model, "Identity", info = lMetric$id)
    expect_identical(lMeta$AnalysisType, "identity", info = lMetric$id)
    expect_identical(lMeta$Score, "Numerator", info = lMetric$id)
    expect_identical(lMeta$Domain, lMetric$domain, info = lMetric$id)
  }
})

test_that("every census metric declares the column it is checked on (#58)", {
  # The guard is only as good as the declaration a reader checks it against.
  for (lMetric in LCENSUS) {
    lSpec <- CensusWorkflow(lMetric$id)$spec

    expect_true(lMetric$domain %in% names(lSpec), info = lMetric$id)
    expect_true("Mapped_SUBJ" %in% names(lSpec), info = lMetric$id)
    expect_true(lMetric$column %in% names(lSpec[[lMetric$domain]]), info = lMetric$id)
    for (strDomain in names(lSpec)) {
      expect_match(strDomain, "^Mapped_", info = paste(lMetric$id, strDomain))
    }
  }
})

test_that("every census metric runs end to end and its row does not flag (#58)", {
  for (lMetric in LCENSUS) {
    lResult <- RunCensus(lMetric$id, CENSUS_DATA())
    dfSummary <- lResult$Analysis_Summary

    expect_identical(
      names(dfSummary),
      c("GroupID", "GroupLevel", "Numerator", "Denominator", "Metric", "Score", "Flag"),
      info = lMetric$id
    )
    expect_identical(nrow(dfSummary), 1L, info = lMetric$id)
    expect_identical(dfSummary$GroupLevel, "Study", info = lMetric$id)
    expect_identical(dfSummary$GroupID, "AA-AA-000-0000", info = lMetric$id)
    expect_identical(dfSummary$Numerator, lMetric$numerator, info = lMetric$id)
    expect_identical(dfSummary$Denominator, 4, info = lMetric$id)
    expect_identical(dfSummary$Score, dfSummary$Numerator, info = lMetric$id)
    expect_true(is.na(dfSummary$Flag), info = lMetric$id)

    # The unsummarised input stays beside the summary, one row per participant.
    expect_identical(nrow(lResult$Analysis_Input), 4L, info = lMetric$id)
  }
})

test_that("no count can exceed the enrolled population it is anchored to (#58)", {
  for (lMetric in LCENSUS) {
    dfSummary <- RunCensus(lMetric$id, CENSUS_DATA())$Analysis_Summary
    if (lMetric$id %in% c("saf0008", "saf0009")) next # person-time, not a count
    expect_lte(dfSummary$Numerator, dfSummary$Denominator, label = lMetric$id)
  }
})

test_that("duplicating a domain row changes no published figure (#58)", {
  # The standing rule from the D0023 design, applied to every metric rather
  # than trusted to the framework.
  for (lMetric in LCENSUS) {
    lData <- CENSUS_DATA()
    nBefore <- RunCensus(lMetric$id, lData)$Analysis_Summary$Numerator

    df <- lData[[lMetric$domain]]
    lData[[lMetric$domain]] <- rbind(df, df[1, , drop = FALSE])
    dfSummary <- RunCensus(lMetric$id, lData)$Analysis_Summary

    expect_identical(dfSummary$Numerator, nBefore, info = lMetric$id)
    expect_identical(dfSummary$Denominator, 4, info = lMetric$id)
  }
})

test_that("a participant in a domain but never enrolled is never counted (#58)", {
  for (lMetric in LCENSUS) {
    if (!lMetric$ghost) next
    lData <- CENSUS_DATA()
    nBefore <- RunCensus(lMetric$id, lData)$Analysis_Summary$Numerator

    df <- lData[[lMetric$domain]]
    dfGhost <- df[1, , drop = FALSE]
    dfGhost$subjid <- "GHOST"
    lData[[lMetric$domain]] <- rbind(df, dfGhost)
    dfSummary <- RunCensus(lMetric$id, lData)$Analysis_Summary

    expect_false("GHOST" %in% RunCensus(lMetric$id, lData)$Analysis_Input$SubjectID, info = lMetric$id)
    expect_identical(dfSummary$Numerator, nBefore, info = lMetric$id)
    expect_lte(dfSummary$Numerator, dfSummary$Denominator, label = lMetric$id)
  }
})

test_that("a declared column that goes missing stops the metric (#58)", {
  # The single largest defect class the rebuild exists to remove, and the one
  # the design assumed the framework handled. gsm.core::CheckSpec() only warns
  # on a missing column, so without the step's own guard every one of these
  # would publish a quiet zero instead.
  for (lMetric in LCENSUS) {
    lData <- CENSUS_DATA()
    lData[[lMetric$domain]][[lMetric$column]] <- NULL

    expect_error(
      suppressWarnings(suppressMessages(
        gsm.core::RunWorkflow(CensusWorkflow(lMetric$id), lData = lData)
      )),
      lMetric$column,
      info = lMetric$id
    )
  }
})

test_that("EVERY declared column, dropped, stops the metric (#58)", {
  # The stronger form of the rule above, and the one that survives a metric
  # being edited later: it is not enough that one column is guarded. A column
  # a definition declares but no step reads would be a promise to a reader that
  # nothing keeps, so every declared column of every census metric is dropped
  # in turn and the metric has to stop.
  for (lMetric in LCENSUS) {
    lSpec <- CensusWorkflow(lMetric$id)$spec
    for (strDomain in names(lSpec)) {
      for (strCol in names(lSpec[[strDomain]])) {
        lData <- CENSUS_DATA()
        lData[[strDomain]][[strCol]] <- NULL

        expect_error(
          suppressWarnings(suppressMessages(
            gsm.core::RunWorkflow(CensusWorkflow(lMetric$id), lData = lData)
          )),
          strCol,
          info = paste(lMetric$id, strDomain, strCol)
        )
      }
    }
  }
})

test_that("a domain the study does not supply stops the metric (#58)", {
  for (lMetric in LCENSUS) {
    lData <- CENSUS_DATA()
    lData[[lMetric$domain]] <- NULL

    expect_error(
      suppressWarnings(suppressMessages(
        gsm.core::RunWorkflow(CensusWorkflow(lMetric$id), lData = lData)
      )),
      info = lMetric$id
    )
  }
})

test_that("an empty domain publishes no row at all, not a zero (#58)", {
  for (lMetric in LCENSUS) {
    lData <- CENSUS_DATA()
    lData[[lMetric$domain]] <- lData[[lMetric$domain]][0, , drop = FALSE]

    expect_identical(
      nrow(RunCensus(lMetric$id, lData)$Analysis_Summary), 0L,
      info = lMetric$id
    )
  }
})

test_that("a populated domain naming nobody is a measured zero (#58)", {
  # The third state, and the only one that is genuinely a zero: the domain ran
  # and the answer was none.
  lData <- CENSUS_DATA()
  lData$Mapped_STUDCOMP$compyn <- NA_character_

  for (strID in c("saf0014", "saf0015")) {
    dfSummary <- RunCensus(strID, lData)$Analysis_Summary
    expect_identical(nrow(dfSummary), 1L, info = strID)
    expect_identical(dfSummary$Numerator, 0, info = strID)
    expect_identical(dfSummary$Denominator, 4, info = strID)
  }
})

test_that("person-time is published in days, and the mean comes out of the pair (#58)", {
  # D0023: participant-days are published as the number actually summed; the
  # report is what presents years.
  dfStudy <- RunCensus("saf0008", CENSUS_DATA())$Analysis_Summary
  dfTreat <- RunCensus("saf0009", CENSUS_DATA())$Analysis_Summary

  expect_identical(dfStudy$Numerator, 100)
  expect_identical(dfStudy$Metric, 25)
  expect_identical(dfTreat$Numerator, 40)
  expect_identical(dfTreat$Metric, 10)
})

test_that("dosed is a recorded first dose, not a positive treatment duration (#58)", {
  # The stated fix. S2 has a first-dose date and zero days on treatment: dosed
  # once and stopped the same day is dosed. The old inference reports them as
  # not dosed, and reports zero for the whole study when the column is absent.
  lData <- CENSUS_DATA()
  expect_identical(RunCensus("saf0007", lData)$Analysis_Summary$Numerator, 3)

  nOldWay <- sum(lData$Mapped_SUBJ$timeontreatment > 0)
  expect_identical(nOldWay, 3L)

  lData$Mapped_SUBJ$firstdosedate[2] <- NA
  expect_identical(RunCensus("saf0007", lData)$Analysis_Summary$Numerator, 2)
})

test_that("randomisation is counted from the randomisation domain, not an arm column (#58)", {
  # The other stated fix: the standard domains carry no treatment-arm column,
  # which is why SafetyCensus() comes out blank on every study but the demo.
  lSpec <- CensusWorkflow("saf0006")$spec

  expect_true("Mapped_Randomization" %in% names(lSpec))
  expect_false(any(grepl("arm", unlist(lapply(lSpec, names)), ignore.case = TRUE)))
})
