MakeAE <- function(subjid, aeser, aerel, aetoxgr = 1, aeacn = NA_character_) {
  data.frame(
    subjid = subjid, aeser = aeser, aerel = aerel,
    aetoxgr = aetoxgr, aeacn = aeacn,
    stringsAsFactors = FALSE
  )
}

test_that("Input_SafetyAE returns the analyticsInput columns at Subject level (#45)", {
  df <- Input_SafetyAE(MakeAE("S1", "Y", "Y", 4))

  expect_true(all(
    c("SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric") %in%
      names(df)
  ))
  expect_identical(df$GroupLevel, "Subject")
  expect_identical(df$GroupID, df$SubjectID)
  expect_identical(df$Metric, df$Numerator)
})

test_that("Input_SafetyAE tiers on seriousness, relatedness and severity (#45)", {
  df <- Input_SafetyAE(rbind(
    MakeAE("none", "N", "N", 1),
    MakeAE("related", "N", "Y", 2),
    MakeAE("serious", "Y", "N", 3),
    MakeAE("seriousRelatedLow", "Y", "Y", 2),
    MakeAE("seriousRelatedG4", "Y", "Y", 4)
  ))
  vTier <- stats::setNames(df$Numerator, df$SubjectID)

  expect_identical(vTier[["none"]], 0)
  expect_identical(vTier[["related"]], 1)
  expect_identical(vTier[["serious"]], 2)
  # Serious AND related but only grade 2 stays at the serious tier.
  expect_identical(vTier[["seriousRelatedLow"]], 2)
  expect_identical(vTier[["seriousRelatedG4"]], 3)
})

test_that("Input_SafetyAE takes a participant's worst event, not their first (#45)", {
  df <- Input_SafetyAE(rbind(
    MakeAE("S1", "N", "N", 1),
    MakeAE("S1", "Y", "Y", 4),
    MakeAE("S1", "N", "Y", 1)
  ))

  expect_identical(nrow(df), 1L)
  expect_identical(df$Numerator, 3)
  expect_identical(df$AECount, 3)
  expect_identical(df$SeriousCount, 1)
  expect_identical(df$RelatedCount, 2)
})

test_that("Input_SafetyAE honours the severity grade cut it is given (#45)", {
  df <- MakeAE("S1", "Y", "Y", 3)

  expect_identical(Input_SafetyAE(df)$Numerator, 2)
  expect_identical(Input_SafetyAE(df, nSeriousRelatedGrade = 3)$Numerator, 3)
})

test_that("Input_SafetyAE leaves the discontinuation leg inactive without a column (#45)", {
  df <- Input_SafetyAE(MakeAE("S1", "N", "N", 1, aeacn = "DRUG WITHDRAWN"))

  expect_false(df$ActionColumnPresent)
  expect_false(df$Discontinuation)
  expect_identical(df$Numerator, 0)
})

test_that("Input_SafetyAE reads discontinuation when told which column carries it (#45)", {
  df <- Input_SafetyAE(
    rbind(
      MakeAE("withdrawn", "N", "N", 1, aeacn = "DRUG WITHDRAWN"),
      MakeAE("continued", "N", "N", 1, aeacn = "DOSE NOT CHANGED")
    ),
    strActionCol = "aeacn"
  )
  vTier <- stats::setNames(df$Numerator, df$SubjectID)

  expect_true(all(df$ActionColumnPresent))
  expect_identical(vTier[["withdrawn"]], 2)
  expect_identical(vTier[["continued"]], 0)
})

test_that("Input_SafetyAE scores AE-free participants as an explicit tier 0 (#45)", {
  dfSubjects <- data.frame(subjid = c("S1", "S2", "S3"), stringsAsFactors = FALSE)
  df <- Input_SafetyAE(MakeAE("S1", "Y", "Y", 4), dfSubjects = dfSubjects)

  # Unlike the lab metrics, absence of AEs is a real result, not missing data:
  # every enrolled participant is scored.
  expect_identical(nrow(df), 3L)
  expect_identical(stats::setNames(df$Numerator, df$SubjectID)[["S2"]], 0)
  expect_identical(stats::setNames(df$AECount, df$SubjectID)[["S2"]], 0)
})

test_that("Input_SafetyAE rejects data missing a mapped column (#45)", {
  expect_error(Input_SafetyAE(MakeAE("S1", "Y", "Y")[, -2]), "aeser")
  expect_error(Input_SafetyAE("not a data frame"), "data.frame")
})
