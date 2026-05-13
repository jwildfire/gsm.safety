test_that("AE Explorer report scaffold is workr-shaped", {
  report_path <- system.file("workflow", "3_reports", "ae_explorer.yaml", package = "gsm.safety")
  expect_true(file.exists(report_path))

  report_text <- readLines(report_path, warn = FALSE)
  expect_true(any(grepl("Type: Report", report_text, fixed = TRUE)))
  expect_true(any(grepl("ID: ae_explorer", report_text, fixed = TRUE)))
  expect_true(any(grepl("spec:", report_text, fixed = TRUE)))
  expect_true(any(grepl("steps:", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::MakeAeExplorerSettings", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::MakeAeExplorerManifest", report_text, fixed = TRUE)))
})

test_that("AE Explorer scaffold functions return a manifest", {
  lSpec <- list(
    Mapped_SUBJ = list(subjid = list(type = "character")),
    Mapped_AE = list(
      subjid = list(type = "character"),
      mdrpt_nsv = list(type = "character"),
      mdrsoc_nsv = list(type = "character")
    )
  )
  lSettings <- MakeAeExplorerSettings(lSpec)
  lData <- list(
    Mapped_SUBJ = data.frame(subjid = "01"),
    Mapped_AE = data.frame(
      subjid = "01",
      mdrpt_nsv = "Headache",
      mdrsoc_nsv = "Nervous system disorders"
    )
  )

  manifest <- MakeAeExplorerManifest(
    lData = lData,
    lSettings = lSettings,
    lMeta = list(Type = "Report", ID = "ae_explorer", Output = "html")
  )

  expect_equal(manifest$report_id, "ae_explorer")
  expect_equal(manifest$domains$dm, "Mapped_SUBJ")
  expect_equal(manifest$settings$aes$term_col, "mdrpt_nsv")
  expect_true("treatment_col" %in% names(manifest$gaps))
  expect_equal(manifest$status, "scaffold")
})
