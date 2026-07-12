test_that("ExampleData reads the adbds example data with sensible types (#37)", {
  dfResults <- ExampleData("adbds")

  expect_s3_class(dfResults, "data.frame")
  expect_gt(nrow(dfResults), 0)
  expect_identical(
    names(dfResults),
    c(
      "USUBJID", "SITE", "SITEID", "SEX", "RACE", "ARM", "VISIT", "VISITNUM",
      "TEST", "STRESU", "STRESN", "STNRLO", "STNRHI"
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
