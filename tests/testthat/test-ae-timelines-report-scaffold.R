test_that("AE Timelines report scaffold is workr-shaped", {
  report_path <- system.file("workflow", "3_reports", "ae_timelines.yaml", package = "gsm.safety")
  if (!nzchar(report_path)) {
    candidates <- c(
      file.path("inst", "workflow", "3_reports", "ae_timelines.yaml"),
      file.path("..", "..", "inst", "workflow", "3_reports", "ae_timelines.yaml")
    )
    report_path <- candidates[file.exists(candidates)][[1]]
  }
  expect_true(file.exists(report_path))

  report_text <- readLines(report_path, warn = FALSE)
  expect_true(any(grepl("Type: Report", report_text, fixed = TRUE)))
  expect_true(any(grepl("ID: ae_timelines", report_text, fixed = TRUE)))
  expect_true(any(grepl("spec:", report_text, fixed = TRUE)))
  expect_true(any(grepl("steps:", report_text, fixed = TRUE)))
  expect_true(any(grepl("widgetSettings:", report_text, fixed = TRUE)))
  expect_true(any(grepl("name: safetyCharts::init_aeTimelines", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::RenderSafetyChartsWidget", report_text, fixed = TRUE)))
})


test_that("AE Timelines workflow renderer saves an initialized widget", {
  skip_if_not_installed("gsm.datasim")
  skip_if_not_installed("safetyCharts")
  skip_if_not_installed("htmlwidgets")

  lData <- MakeExampleData()
  initialized <- safetyCharts::init_aeTimelines(
    data = lData$Mapped_AE,
    settings = list(
      id_col = "subjid",
      stdy_col = "aestdy",
      endy_col = "aeendy",
      seq_col = "aeseq",
      term_col = "mdrpt_nsv",
      serious_col = "aeser",
      severity_col = "aesev"
    )
  )

  report <- RenderSafetyChartsWidget(
    lInitialized = initialized,
    strWidgetName = "aeTimelines",
    strOutputDir = tempdir(),
    strOutputFile = "ae_timelines_test"
  )

  expect_true(file.exists(report$path))
  expect_s3_class(report$widget, "htmlwidget")
  expect_true(any(grepl("aeTimelines", readLines(report$path, warn = FALSE), fixed = TRUE)))
})
