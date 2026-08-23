# The qualification records ship with the package (#63).
#
# Three records - one per step of the SafetyCensus rebuild - are installed
# content rather than repository content, so that the checks which read them
# run in the context that gates the merge. This file guards that arrangement.
# It never skips on the thing that matters: a record that has stopped shipping
# is a failure here, not an unavailable context, because the alternative is the
# failure #63 exists to fix - three checks that quietly did not run.

test_that("every qualification record is installed with the package (#63)", {
  for (strFile in CHR_QUALIFICATION_RECORDS) {
    strPath <- QualificationRecordPath(strFile)
    expect_true(
      nzchar(strPath) && file.exists(strPath),
      label = paste0("inst/qualification/", strFile, " is installed")
    )
    if (nzchar(strPath) && file.exists(strPath)) {
      expect_gt(length(readLines(strPath, warn = FALSE)), 0L)
    }
  }

  cat(sprintf(
    "[QUALIFICATION] %d records installed and readable here: %s\n",
    length(CHR_QUALIFICATION_RECORDS),
    paste(CHR_QUALIFICATION_RECORDS, collapse = ", ")
  ))
})

test_that("no qualification record ships without a check that reads it (#63)", {
  # A fourth record added to inst/qualification/ and nowhere else would ship as
  # evidence with nothing asserting it stays true. This is what makes adding
  # the check part of adding the record.
  strDir <- system.file("qualification", package = "gsm.safety")
  expect_true(nzchar(strDir))
  if (nzchar(strDir)) {
    expect_setequal(
      list.files(strDir, pattern = "[.]md$"), CHR_QUALIFICATION_RECORDS
    )
  }
})

test_that("no qualification record is left behind in design/ (#63)", {
  # design/ is repository content: working notes that are not qualification
  # records, .Rbuildignore'd and absent from the built package. This guard can
  # therefore only run in the source tree, and says so rather than pretending
  # to have checked. The checks that matter - the ones above, and the
  # document-agreement layers - run everywhere.
  strDesign <- testthat::test_path("..", "..", "design")
  skip_if_not(
    dir.exists(strDesign),
    "design/ is repository content and this guard runs in the source tree"
  )
  expect_identical(
    list.files(strDesign, pattern = "-qualification[.]md$"), character(0)
  )
})
