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
  expect_true(any(grepl("widgetSettings:", report_text, fixed = TRUE)))
  expect_true(any(grepl("treatment_col: sex", report_text, fixed = TRUE)))
  expect_true(any(grepl("name: list", report_text, fixed = TRUE)))
  expect_true(any(grepl("safetyCharts::init_aeExplorer", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::RenderAeExplorerWidget", report_text, fixed = TRUE)))
})


test_that("example data comes from gsm.datasim with expected mapped columns", {
  skip_if_not_installed("gsm.datasim")

  lData <- MakeExampleData(nSubjects = 6, nSites = 2, nAe = 8, seed = 11)

  expect_named(lData, c("Mapped_SUBJ", "Mapped_AE"))
  expect_true(all(c("subjid", "sex") %in% names(lData$Mapped_SUBJ)))
  expect_true(all(c("subjid", "mdrpt_nsv", "mdrsoc_nsv", "aeser", "aetoxgr", "aerel") %in% names(lData$Mapped_AE)))
  expect_true(nrow(lData$Mapped_SUBJ) > 0)
  expect_true(nrow(lData$Mapped_AE) > 0)
})


test_that("AE Explorer workflow renderer saves an initialized widget", {
  skip_if_not_installed("gsm.datasim")
  skip_if_not_installed("safetyCharts")
  skip_if_not_installed("htmlwidgets")

  lData <- MakeExampleData()
  initialized <- safetyCharts::init_aeExplorer(
    data = list(
      dm = lData$Mapped_SUBJ,
      aes = lData$Mapped_AE
    ),
    settings = list(
      dm = list(id_col = "subjid", treatment_col = "sex"),
      aes = list(id_col = "subjid", term_col = "mdrpt_nsv", bodsys_col = "mdrsoc_nsv")
    )
  )

  report <- RenderAeExplorerWidget(
    lInitialized = initialized,
    strOutputDir = tempdir(),
    strOutputFile = "ae_explorer_test"
  )

  expect_true(file.exists(report$path))
  expect_s3_class(report$widget, "htmlwidget")
  expect_true(any(grepl("aeExplorer", readLines(report$path, warn = FALSE), fixed = TRUE)))
})
