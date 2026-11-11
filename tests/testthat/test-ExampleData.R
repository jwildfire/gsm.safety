test_that("ExampleData reads the adbds example data with sensible types (#37)", {
  dfResults <- ExampleData("adbds")

  expect_s3_class(dfResults, "data.frame")
  expect_gt(nrow(dfResults), 0)
  expect_identical(
    names(dfResults),
    c(
      "USUBJID", "SITE", "SITEID", "SEX", "RACE", "ARM", "VISIT", "VISITNUM",
      "TEST", "STRESU", "STRESN", "STNRLO", "STNRHI", "DY", "ABLFL"
    )
  )
  expect_type(dfResults$USUBJID, "character")
  expect_type(dfResults$SITEID, "character")
  expect_type(dfResults$TEST, "character")
  expect_true(is.numeric(dfResults$VISITNUM))
  expect_true(is.numeric(dfResults$STRESN))
  expect_true(is.numeric(dfResults$STNRLO))
  expect_true(is.numeric(dfResults$STNRHI))
})

test_that("ExampleData reads the adae example data with sensible types (#37)", {
  dfAE <- ExampleData("adae")

  expect_s3_class(dfAE, "data.frame")
  expect_gt(nrow(dfAE), 0)
  expect_identical(
    names(dfAE),
    c(
      "USUBJID", "ARM", "AESEQ", "AEBODSYS", "AEDECOD", "AETERM", "AESEV",
      "AESER", "ASTDY", "AENDY"
    )
  )
  expect_type(dfAE$USUBJID, "character")
  expect_type(dfAE$AETERM, "character")
  expect_true(is.numeric(dfAE$AESEQ))
  expect_true(is.numeric(dfAE$ASTDY))
  expect_true(is.numeric(dfAE$AENDY))
})

test_that("ExampleData converts blank numeric fields to NA without warnings (#37)", {
  expect_no_warning(dfAE <- ExampleData("adae"))
  expect_true(anyNA(dfAE$AENDY))
})

test_that("ExampleData defaults to adbds and rejects unknown datasets (#37)", {
  expect_identical(ExampleData(), ExampleData("adbds"))
  expect_error(ExampleData("nope"))
})

test_that("ExampleData reads the adsl population extract with sensible types (#71)", {
  dfSL <- ExampleData("adsl")

  expect_s3_class(dfSL, "data.frame")
  expect_gt(nrow(dfSL), 0)
  expect_identical(names(dfSL), c("USUBJID", "ARM", "EOSDY", "EOSSTT"))
  expect_type(dfSL$USUBJID, "character")
  expect_type(dfSL$EOSSTT, "character")
  expect_true(is.numeric(dfSL$EOSDY))

  # One row per participant: this frame is Widget_TimeToEvent()'s denominator,
  # and a duplicate would double-count someone at risk.
  expect_identical(anyDuplicated(dfSL$USUBJID), 0L)

  # Every participant with an adverse event must be in the population, or the
  # module drops their events as belonging to an unknown participant.
  dfAE <- ExampleData("adae")
  expect_true(all(dfAE$USUBJID %in% dfSL$USUBJID))
})

test_that("the lab, vital-sign and ECG examples carry the study day and the baseline flag (#165)", {
  # safety.viz v1.12.0's demo data: every record keeps its ADaM study day (DY)
  # and its baseline flag (ABLFL) beside its visit, so a chart can plot real
  # days and read the baseline instead of guessing it.
  for (strDataset in c("adbds", "adbds_abnbl", "adeg")) {
    dfData <- ExampleData(strDataset)
    expect_true(all(c("VISIT", "VISITNUM", "DY", "ABLFL") %in% names(dfData)), label = strDataset)
    expect_true(is.numeric(dfData$DY), label = paste(strDataset, "DY numeric"))
    expect_type(dfData$ABLFL, "character")
    expect_true(all(dfData$ABLFL %in% c("Y", "")), label = paste(strDataset, "ABLFL values"))
    # The study day is real days, not the visit number in disguise.
    expect_false(isTRUE(all.equal(dfData$DY, dfData$VISITNUM)), label = paste(strDataset, "DY != VISITNUM"))
    expect_gt(sum(dfData$ABLFL == "Y"), 0)
  }

  # Participant 01-701-1028: the requirement's worked case. Their labs sit at
  # real study days, so a day-21 adverse event can be placed among them.
  dfLabs <- ExampleData("adbds")
  dfOne <- dfLabs[dfLabs$USUBJID == "01-701-1028", ]
  expect_gt(nrow(dfOne), 0)
  expect_true(any(dfOne$DY < 21, na.rm = TRUE))
  expect_true(any(dfOne$DY > 21, na.rm = TRUE))
})
