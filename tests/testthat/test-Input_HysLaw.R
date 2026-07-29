MakeLiverData <- function(...) {
  lRows <- list(...)
  do.call(rbind, lapply(names(lRows), function(strID) {
    nVals <- lRows[[strID]]
    data.frame(
      subjid = strID,
      lbtstnam = c("ALT", "AST", "TB", "ALP"),
      lbstresn = as.numeric(nVals),
      lbstnrhi = c(40, 40, 20, 120),
      stringsAsFactors = FALSE
    )
  }))
}

LMEASURES <- list(ALT = "ALT", AST = "AST", TB = "TB", ALP = "ALP")

test_that("Input_HysLaw returns the analyticsInput columns at Subject level (#45)", {
  df <- Input_HysLaw(MakeLiverData(S1 = c(150, 120, 60, 90)), lMeasureValues = LMEASURES)

  expect_true(all(
    c("SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric") %in%
      names(df)
  ))
  expect_identical(df$GroupLevel, "Subject")
  expect_identical(df$GroupID, df$SubjectID)
  expect_identical(df$Denominator, 1)
  # Analyze_Identity copies Numerator to Score, so Metric must equal the tier.
  expect_identical(df$Metric, df$Numerator)
})

test_that("Input_HysLaw places participants in the four eDISH quadrants (#45)", {
  df <- Input_HysLaw(
    MakeLiverData(
      # ALT 0.5x, TB 0.4x, ALP 0.7x -> neither axis
      normal = c(20, 25, 8, 80),
      # ALT 3.75x, TB 0.4x -> aminotransferase only (Temple's Corollary)
      temple = c(150, 120, 8, 80),
      # ALT 0.5x, TB 3x -> bilirubin only (hyperbilirubinaemia)
      hyperbili = c(20, 25, 60, 80),
      # ALT 3.75x, TB 3x, ALP 2.5x -> both axes, cholestatic
      cholestatic = c(150, 120, 60, 300),
      # ALT 3.75x, TB 3x, ALP 0.75x -> both axes, hepatocellular
      hyslaw = c(150, 120, 60, 90)
    ),
    lMeasureValues = LMEASURES
  )
  vTier <- stats::setNames(df$Numerator, df$SubjectID)

  expect_identical(vTier[["normal"]], 0)
  expect_identical(vTier[["temple"]], 1)
  expect_identical(vTier[["hyperbili"]], 1)
  expect_identical(vTier[["cholestatic"]], 2)
  expect_identical(vTier[["hyslaw"]], 3)
  expect_identical(
    stats::setNames(df$Quadrant, df$SubjectID)[["hyslaw"]],
    "Potential Hy's Law"
  )
})

test_that("Input_HysLaw scores the peak value, not the last one (#45)", {
  # Two visits: the second is normal. The peak still places the participant.
  df <- rbind(
    MakeLiverData(S1 = c(150, 120, 60, 90)),
    MakeLiverData(S1 = c(10, 10, 4, 60))
  )
  out <- Input_HysLaw(df, lMeasureValues = LMEASURES)

  expect_identical(nrow(out), 1L)
  expect_identical(out$Numerator, 3)
  expect_identical(out$PeakALT_xULN, 3.75)
})

test_that("Input_HysLaw honours the cut-points it is given (#45)", {
  df <- MakeLiverData(S1 = c(150, 120, 60, 90)) # ALT 3.75x, TB 3x, ALP 0.75x

  # Raising the aminotransferase cut above the peak drops it out of the quadrant.
  expect_identical(
    Input_HysLaw(df, lMeasureValues = LMEASURES, nAminotransferaseCut = 5)$Numerator,
    1
  )
  # Lowering the cholestatic cut below the peak ALP re-reads it as cholestatic.
  expect_identical(
    Input_HysLaw(df, lMeasureValues = LMEASURES, nCholestaticCut = 0.5)$Numerator,
    2
  )
})

test_that("Input_HysLaw treats an unmeasured ALP as unable to exclude cholestasis (#45)", {
  df <- MakeLiverData(S1 = c(150, 120, 60, 90))
  df <- df[df$lbtstnam != "ALP", ]

  out <- Input_HysLaw(df, lMeasureValues = LMEASURES)
  expect_identical(out$Numerator, 2)
  expect_true(is.na(out$PeakALP_xULN))
})

test_that("Input_HysLaw omits participants it cannot place, rather than scoring them 0 (#45)", {
  df <- MakeLiverData(withTB = c(150, 120, 60, 90), noTB = c(150, 120, 60, 90))
  df <- df[!(df$subjid == "noTB" & df$lbtstnam == "TB"), ]

  out <- Input_HysLaw(df, lMeasureValues = LMEASURES)
  expect_identical(out$SubjectID, "withTB")
})

test_that("Input_HysLaw drops results with an unusable ULN (#45)", {
  df <- MakeLiverData(S1 = c(150, 120, 60, 90))
  df$lbstnrhi <- 0

  expect_identical(nrow(Input_HysLaw(df, lMeasureValues = LMEASURES)), 0L)
})

test_that("Input_HysLaw rejects data missing a mapped column (#45)", {
  df <- MakeLiverData(S1 = c(150, 120, 60, 90))

  expect_error(Input_HysLaw(df[, -1], lMeasureValues = LMEASURES), "subjid")
  expect_error(Input_HysLaw("not a data frame"), "data.frame")
})
