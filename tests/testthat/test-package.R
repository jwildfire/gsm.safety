test_that("package metadata is available", {
  expect_type(utils::packageDescription("gsm.safety")$Package, "character")
  expect_equal(utils::packageDescription("gsm.safety")$Package, "gsm.safety")
})
