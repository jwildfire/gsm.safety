SUBJECTS <- data.frame(
  subjid = c("S1", "S2", "S3", "S4"),
  arm = c("A", "B", "A", ""),
  timeonstudy = c(365, 180, 90, 30),
  timeontreatment = c(365, 180, 0, 30),
  stringsAsFactors = FALSE
)

CensusValue <- function(lOut, strLabel) {
  lOut$Census$Value[lOut$Census$Label == strLabel]
}

test_that("SafetyCensus counts the study's denominators (#45)", {
  lOut <- SafetyCensus(SUBJECTS)

  expect_identical(CensusValue(lOut, "Enrolled participants"), 4)
  expect_identical(CensusValue(lOut, "Randomised to an arm"), 3)
  expect_identical(CensusValue(lOut, "Received study drug"), 3)
})

test_that("SafetyCensus accumulates person-time in years (#45)", {
  lOut <- SafetyCensus(SUBJECTS)

  expect_equal(CensusValue(lOut, "Person-years on study"), round(665 / 365.25, 1))
  expect_equal(CensusValue(lOut, "Person-years on treatment"), round(575 / 365.25, 1))
  # The untreated participant is excluded from the median, not counted as zero.
  expect_identical(CensusValue(lOut, "Median days on treatment"), 180)
})

test_that("SafetyCensus reports coverage as a count against a denominator (#45)", {
  dfLabs <- data.frame(
    subjid = c("S1", "S1", "S2", "S3"),
    visnam = c("Baseline", "Week 4", "Baseline", "Baseline"),
    visnum = c(1, 2, 1, 1),
    stringsAsFactors = FALSE
  )
  dfCoverage <- SafetyCensus(SUBJECTS, dfLabs = dfLabs)$Coverage

  expect_identical(dfCoverage$Visit, c("Baseline", "Week 4"))
  expect_identical(dfCoverage$Participants, c(3, 1))
  # Four participants are enrolled, so Week 4 is 1 of 4 — the count alone would
  # read as "one result", not as "three quarters missing".
  expect_identical(unique(dfCoverage$Expected), 4)
  expect_identical(unique(dfCoverage$Domain), "Labs")
})

test_that("SafetyCensus orders coverage by visit number, not alphabetically (#45)", {
  dfLabs <- data.frame(
    subjid = "S1",
    visnam = c("Week 12", "Baseline", "Week 2"),
    visnum = c(8, 1, 3),
    stringsAsFactors = FALSE
  )
  dfCoverage <- SafetyCensus(SUBJECTS, dfLabs = dfLabs)$Coverage

  expect_identical(dfCoverage$Visit, c("Baseline", "Week 2", "Week 12"))
})

test_that("SafetyCensus keeps lab and ECG coverage in one table, tagged by domain (#45)", {
  dfLabs <- data.frame(subjid = "S1", visnam = "Baseline", visnum = 1, stringsAsFactors = FALSE)
  dfECG <- data.frame(subjid = c("S1", "S2"), visnam = "Baseline", visnum = 1, stringsAsFactors = FALSE)
  dfCoverage <- SafetyCensus(SUBJECTS, dfLabs = dfLabs, dfECG = dfECG)$Coverage

  expect_identical(dfCoverage$Domain, c("Labs", "ECG"))
  expect_identical(dfCoverage$Participants, c(1, 2))
})

test_that("SafetyCensus reads disposition and deaths from the completion domain (#45)", {
  dfDisposition <- data.frame(
    subjid = c("S1", "S2", "S3", "S4"),
    compyn = c("Y", "N", "N", ""),
    compreas = c("", "Death", "Withdrew Consent", ""),
    stringsAsFactors = FALSE
  )
  lOut <- SafetyCensus(SUBJECTS, dfDisposition = dfDisposition)

  expect_identical(CensusValue(lOut, "Deaths"), 1)
  vState <- stats::setNames(lOut$Disposition$Participants, lOut$Disposition$State)
  expect_identical(vState[["Completed"]], 1)
  expect_identical(vState[["Died"]], 1)
  expect_identical(vState[["Discontinued - Withdrew Consent"]], 1)
  expect_identical(vState[["Ongoing"]], 1)
})

test_that("SafetyCensus names the participants its disposition domain does not cover (#45)", {
  # The demo's disposition domain covers a subset of the population; reporting
  # the rest as "ongoing" would be an invention.
  dfDisposition <- data.frame(
    subjid = c("S1", "S2"), compyn = c("Y", "Y"), compreas = "",
    stringsAsFactors = FALSE
  )
  lOut <- SafetyCensus(SUBJECTS, dfDisposition = dfDisposition)
  vState <- stats::setNames(lOut$Disposition$Participants, lOut$Disposition$State)

  expect_identical(vState[["Not in the disposition domain"]], 2)
  expect_identical(
    CensusValue(lOut, "Participants with a disposition record"), 2
  )
})

test_that("SafetyCensus reports an absent domain as NA, never as zero (#45)", {
  lOut <- SafetyCensus(SUBJECTS)

  expect_true(is.na(CensusValue(lOut, "Deaths")))
  expect_true(is.na(CensusValue(lOut, "Participants with a lab result")))
  expect_identical(nrow(lOut$Coverage), 0L)
  expect_identical(nrow(lOut$Disposition), 0L)
})

test_that("SafetyCensus counts only enrolled participants as assessed (#45)", {
  # A stray ID in a domain that is not in the subject-level population must not
  # inflate a follow-up numerator past its denominator.
  dfLabs <- data.frame(
    subjid = c("S1", "S2", "GHOST"), visnam = "Baseline", visnum = 1,
    stringsAsFactors = FALSE
  )
  lOut <- SafetyCensus(SUBJECTS, dfLabs = dfLabs)

  expect_identical(CensusValue(lOut, "Participants with a lab result"), 2)
})

test_that("SafetyCensus rejects a subject domain it cannot key on (#45)", {
  expect_error(SafetyCensus(SUBJECTS[, -1]), "subjid")
  expect_error(SafetyCensus("not a data frame"), "data.frame")
})
