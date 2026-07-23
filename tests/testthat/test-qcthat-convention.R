test_that("every test in the package carries a qcthat issue reference (#27)", {
  strTestDir <- testthat::test_path()
  chrTestFiles <- list.files(strTestDir, pattern = "^test-.*[.][Rr]$", full.names = TRUE)
  expect_gt(length(chrTestFiles), 0)

  chrTestNames <- unlist(lapply(chrTestFiles, function(strFile) {
    exprs <- parse(strFile, keep.source = FALSE)
    unlist(lapply(exprs, function(expr) {
      if (is.call(expr) && identical(expr[[1]], as.name("test_that"))) {
        as.character(expr[[2]])
      }
    }))
  }))

  chrUnlinked <- chrTestNames[!grepl("\\(#\\d+(, #\\d+)*\\)$", chrTestNames)]
  expect_identical(
    chrUnlinked,
    character(0),
    label = paste("Tests missing a trailing (#N) issue reference:", paste(chrUnlinked, collapse = "; "))
  )
})
