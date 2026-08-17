MetricWorkflow <- function(strID) {
  strPath <- system.file(
    "workflow", "2_metrics", paste0(strID, ".yaml"),
    package = "gsm.safety"
  )
  testthat::skip_if(!nzchar(strPath), paste("no workflow yaml for", strID))
  yaml::read_yaml(strPath)
}

CHR_METRICS <- c("saf0001", "saf0002", "saf0003")

test_that("every metric workflow declares the pat0015 participant-level meta (#45)", {
  for (strID in CHR_METRICS) {
    lWorkflow <- MetricWorkflow(strID)
    lMeta <- lWorkflow$meta

    expect_identical(lMeta$Type, "Analysis", info = strID)
    expect_identical(lMeta$ID, strID, info = strID)
    expect_identical(lMeta$GroupLevel, "Subject", info = strID)
    expect_identical(lMeta$Model, "Identity", info = strID)
    expect_identical(lMeta$AnalysisType, "identity", info = strID)
    expect_identical(lMeta$Score, "Numerator", info = strID)
    # Participant flags feed a case-review queue, never a site risk score.
    expect_false(isTRUE(lMeta$GenerateRiskSignal), info = strID)

    # gsm.reporting::MakeMetric() turns meta into one tibble row, so every
    # meta value has to be a length-1 scalar.
    for (strKey in names(lMeta)) {
      expect_length(lMeta[[strKey]], 1L)
    }

    # Flag() requires exactly one more flag value than threshold cut-points.
    nThreshold <- gsm.core::ParseThreshold(lMeta$Threshold)
    vFlag <- gsm.core::ParseThreshold(lMeta$Flag, bSort = FALSE)
    expect_length(vFlag, length(nThreshold) + 1L)
  }
})

test_that("metric IDs do not collide with the gsm.kri metric ranges (#45)", {
  # gsm.kri uses kri####, cou#### and pat####; gsm.safety takes saf####.
  for (strID in CHR_METRICS) {
    expect_match(strID, "^saf[0-9]{4}$")
  }
})

test_that("each metric workflow runs end to end and emits analyticsSummary (#45)", {
  dfLB <- do.call(rbind, lapply(c("S1", "S2"), function(strID) {
    data.frame(
      subjid = strID,
      lbtstnam = c(
        "Alanine Aminotransferase", "Aspartate Aminotransferase",
        "Bilirubin", "Alkaline Phosphatase"
      ),
      lbstresn = if (strID == "S1") c(150, 120, 60, 90) else c(20, 25, 8, 80),
      lbstnrhi = c(40, 40, 20, 120),
      stringsAsFactors = FALSE
    )
  }))
  dfEG <- data.frame(
    subjid = c("S1", "S1", "S2", "S2"),
    egtstnam = "QTcF",
    egstresn = c(400, 505, 390, 415),
    egbase = c(400, 400, 390, 390),
    egchg = c(0, 105, 0, 25),
    egblfl = c("Y", "", "Y", ""),
    stringsAsFactors = FALSE
  )
  dfAE <- data.frame(
    subjid = c("S1", "S2"),
    aeser = c("Y", "N"),
    aerel = c("Y", "N"),
    aetoxgr = c(4, 1),
    stringsAsFactors = FALSE
  )
  dfSUBJ <- data.frame(subjid = c("S1", "S2"), stringsAsFactors = FALSE)

  lData <- list(
    Mapped_LB = dfLB, Mapped_EG = dfEG,
    Mapped_AE = dfAE, Mapped_SUBJ = dfSUBJ
  )

  for (strID in CHR_METRICS) {
    lResult <- suppressWarnings(suppressMessages(
      gsm.core::RunWorkflow(MetricWorkflow(strID), lData = lData)
    ))
    dfSummary <- lResult$Analysis_Summary

    expect_true(is.data.frame(dfSummary), info = strID)
    expect_identical(
      names(dfSummary),
      c("GroupID", "GroupLevel", "Numerator", "Denominator", "Metric", "Score", "Flag"),
      info = strID
    )
    expect_identical(unique(dfSummary$GroupLevel), "Subject", info = strID)
    # Analyze_Identity copies Numerator to Score; the tier survives the chain.
    expect_identical(dfSummary$Score, dfSummary$Numerator, info = strID)

    # S1 is the flagged participant in all three fixtures; S2 is clean.
    vFlag <- stats::setNames(dfSummary$Flag, dfSummary$GroupID)
    expect_identical(vFlag[["S1"]], 2, info = strID)
    expect_identical(vFlag[["S2"]], 0, info = strID)

    # The unsummarised input keeps the evidence a reviewer needs.
    expect_true(nrow(lResult$Analysis_Input) >= 2L, info = strID)
    expect_gt(ncol(lResult$Analysis_Input), ncol(dfSummary))
  }
})

test_that("metric workflows read only mapped domains their spec declares (#45)", {
  for (strID in CHR_METRICS) {
    lWorkflow <- MetricWorkflow(strID)
    chrSpec <- names(lWorkflow$spec)

    expect_gt(length(chrSpec), 0L)
    for (strDomain in chrSpec) {
      expect_match(strDomain, "^Mapped_", info = paste(strID, strDomain))
    }
  }
})
