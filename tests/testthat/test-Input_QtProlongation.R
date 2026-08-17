# `base` defaults to `value`, so a fixture with no baseline specified has a
# change of zero and exercises the absolute cuts alone.
MakeECG <- function(subjid, value, base = value, change = NA, blfl = "", test = "QTcF") {
  data.frame(
    subjid = subjid,
    egtstnam = test,
    egstresn = value,
    egbase = base,
    egchg = change,
    egblfl = blfl,
    stringsAsFactors = FALSE
  )
}

test_that("Input_QtProlongation returns the analyticsInput columns at Subject level (#45)", {
  df <- Input_QtProlongation(MakeECG("S1", 460))

  expect_true(all(
    c("SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric") %in%
      names(df)
  ))
  expect_identical(df$GroupLevel, "Subject")
  expect_identical(df$GroupID, df$SubjectID)
  expect_identical(df$Metric, df$Numerator)
})

test_that("Input_QtProlongation tiers on the ICH E14 absolute cuts (#45)", {
  df <- Input_QtProlongation(rbind(
    MakeECG("clean", 440),
    MakeECG("t450", 455),
    MakeECG("t480", 485),
    MakeECG("t500", 505)
  ))
  vTier <- stats::setNames(df$Numerator, df$SubjectID)

  expect_identical(vTier[["clean"]], 0)
  expect_identical(vTier[["t450"]], 1)
  expect_identical(vTier[["t480"]], 2)
  expect_identical(vTier[["t500"]], 3)
})

test_that("Input_QtProlongation tiers on change from baseline as well as absolutes (#45)", {
  # 430 ms is below every absolute cut; the change is what escalates it.
  df <- Input_QtProlongation(rbind(
    MakeECG("chg30", 430, base = 395, change = 35),
    MakeECG("chg60", 430, base = 360, change = 70)
  ))
  vTier <- stats::setNames(df$Numerator, df$SubjectID)

  expect_identical(vTier[["chg30"]], 1)
  expect_identical(vTier[["chg60"]], 3)
})

test_that("Input_QtProlongation derives change when the change column is blank (#45)", {
  df <- Input_QtProlongation(MakeECG("S1", 430, base = 360, change = NA))

  expect_identical(df$MaxChange, 70)
  expect_identical(df$Numerator, 3)
})

test_that("Input_QtProlongation scores only post-baseline records (#45)", {
  # The out-of-range value IS the baseline: a high screening QTc is the
  # reference, not a treatment-emergent finding.
  df <- Input_QtProlongation(rbind(
    MakeECG("S1", 505, blfl = "Y"),
    MakeECG("S1", 420, blfl = "")
  ))

  expect_identical(df$MaxValue, 420)
  expect_identical(df$Numerator, 0)
})

test_that("Input_QtProlongation omits participants with no post-baseline ECG (#45)", {
  df <- Input_QtProlongation(rbind(
    MakeECG("baselineOnly", 505, blfl = "Y"),
    MakeECG("followed", 420, blfl = "")
  ))

  expect_identical(df$SubjectID, "followed")
})

test_that("Input_QtProlongation reads only the requested ECG parameter (#45)", {
  df <- Input_QtProlongation(rbind(
    MakeECG("S1", 505, test = "QTcB"),
    MakeECG("S1", 420, test = "QTcF")
  ))

  expect_identical(df$MaxValue, 420)
  expect_identical(df$Measure, "QTcF")
})

test_that("Input_QtProlongation honours the cut-points it is given (#45)", {
  df <- MakeECG("S1", 455)

  expect_identical(Input_QtProlongation(df)$Numerator, 1)
  expect_identical(
    Input_QtProlongation(df, vAbsoluteThresholds = c(400, 420, 450))$Numerator,
    3
  )
  expect_error(
    Input_QtProlongation(df, vAbsoluteThresholds = c(450, 500)),
    "three ascending"
  )
})

test_that("Input_QtProlongation rejects data missing a mapped column (#45)", {
  expect_error(Input_QtProlongation(MakeECG("S1", 460)[, -1]), "subjid")
  expect_error(Input_QtProlongation("not a data frame"), "data.frame")
})
