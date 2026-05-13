test_that("AE Explorer report scaffold is workr-shaped", {
  report_path <- system.file("workflow", "3_reports", "ae_explorer.yaml", package = "gsm.safety")
  if (!nzchar(report_path)) {
    candidates <- c(
      file.path("inst", "workflow", "3_reports", "ae_explorer.yaml"),
      file.path("..", "..", "inst", "workflow", "3_reports", "ae_explorer.yaml")
    )
    report_path <- candidates[file.exists(candidates)][[1]]
  }
  expect_true(file.exists(report_path))

  report_text <- readLines(report_path, warn = FALSE)
  expect_true(any(grepl("Type: Report", report_text, fixed = TRUE)))
  expect_true(any(grepl("ID: ae_explorer", report_text, fixed = TRUE)))
  expect_true(any(grepl("spec:", report_text, fixed = TRUE)))
  expect_true(any(grepl("steps:", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::MakeAeExplorerSettings", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::MakeAeExplorerManifest", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::Report_AE_Explorer", report_text, fixed = TRUE)))
})

test_that("AE Explorer workflow functions render a report", {
  lSpec <- list(
    Mapped_SUBJ = list(subjid = list(type = "character")),
    Mapped_AE = list(
      subjid = list(type = "character"),
      mdrpt_nsv = list(type = "character"),
      mdrsoc_nsv = list(type = "character")
    )
  )
  lSettings <- MakeAeExplorerSettings(lSpec)
  lData <- MakeAeExplorerExampleData()

  manifest <- MakeAeExplorerManifest(
    lData = lData,
    lSettings = lSettings,
    lMeta = list(Type = "Report", ID = "ae_explorer", Output = "html")
  )

  report <- Report_AE_Explorer(
    lData = lData,
    lSettings = lSettings,
    lManifest = manifest,
    strOutputDir = tempdir(),
    strOutputFile = "ae_explorer_test"
  )

  expect_equal(manifest$report_id, "ae_explorer")
  expect_equal(manifest$domains$dm, "Mapped_SUBJ")
  expect_equal(manifest$settings$aes$term_col, "mdrpt_nsv")
  expect_true("treatment_col" %in% names(manifest$gaps))
  expect_equal(manifest$status, "ready")
  expect_true(file.exists(report$path))
  expect_match(report$html, "Preferred terms", fixed = TRUE)
  expect_match(report$html, "Headache", fixed = TRUE)
  expect_equal(report$summaries$terms$n[report$summaries$terms$value == "Headache"], 2L)
})

test_that("AE Explorer report validates required domains and columns", {
  lSpec <- list(
    Mapped_SUBJ = list(subjid = list(type = "character")),
    Mapped_AE = list(
      subjid = list(type = "character"),
      mdrpt_nsv = list(type = "character"),
      mdrsoc_nsv = list(type = "character")
    )
  )
  lSettings <- MakeAeExplorerSettings(lSpec)

  expect_error(
    MakeAeExplorerManifest(list(Mapped_SUBJ = data.frame(subjid = "01")), lSettings),
    "Mapped_AE"
  )

  bad_data <- MakeAeExplorerExampleData()
  bad_data$Mapped_AE$mdrpt_nsv <- NULL
  expect_error(
    MakeAeExplorerManifest(bad_data, lSettings),
    "mdrpt_nsv"
  )
})
