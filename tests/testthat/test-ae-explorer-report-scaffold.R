test_that("AE Explorer report scaffold is present", {
  report_path <- system.file("workflow", "3_reports", "ae_explorer.yaml", package = "gsm.safety")
  expect_true(file.exists(report_path))

  report_text <- readLines(report_path, warn = FALSE)
  expect_true(any(grepl("ID: ae_explorer", report_text, fixed = TRUE)))
  expect_true(any(grepl("Mapped_SUBJ", report_text, fixed = TRUE)))
  expect_true(any(grepl("Mapped_AE", report_text, fixed = TRUE)))
  expect_true(any(grepl("mdrpt_nsv", report_text, fixed = TRUE)))
  expect_true(any(grepl("mdrsoc_nsv", report_text, fixed = TRUE)))
  expect_true(any(grepl("status: gap", report_text, fixed = TRUE)))
})
