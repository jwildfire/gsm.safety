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
  expect_true(any(grepl("name: list", report_text, fixed = TRUE)))
  expect_true(any(grepl("safetyCharts::init_aeExplorer", report_text, fixed = TRUE)))
  expect_true(any(grepl("gsm.safety::RenderAeExplorerWidget", report_text, fixed = TRUE)))
})


test_that("AE Explorer workflow functions render a report", {
  lSpec <- list(
    Mapped_SUBJ = list(
      subjid = list(type = "character"),
      sex = list(type = "character")
    ),
    Mapped_AE = list(
      subjid = list(type = "character"),
      mdrpt_nsv = list(type = "character"),
      mdrsoc_nsv = list(type = "character")
    )
  )
  lSettings <- MakeAeExplorerSettings(lSpec)
  lData <- MakeAeExplorerExampleData()

  skip_if_not_installed("safetyCharts")
  skip_if_not_installed("htmlwidgets")

  report <- Report_AE_Explorer(
    lData = lData,
    lSettings = lSettings,
    strOutputDir = tempdir(),
    strOutputFile = "ae_explorer_test"
  )

  expect_true(file.exists(report$path))
  expect_s3_class(report$widget, "htmlwidget")
  expect_true(any(grepl("aeExplorer", readLines(report$path, warn = FALSE), fixed = TRUE)))
  expect_equal(report$summaries$terms$n[report$summaries$terms$value == "Headache"], 2L)
})

test_that("AE Explorer report validates required domains and columns", {
  lSpec <- list(
    Mapped_SUBJ = list(
      subjid = list(type = "character"),
      sex = list(type = "character")
    ),
    Mapped_AE = list(
      subjid = list(type = "character"),
      mdrpt_nsv = list(type = "character"),
      mdrsoc_nsv = list(type = "character")
    )
  )
  lSettings <- MakeAeExplorerSettings(lSpec)

  expect_error(
    Report_AE_Explorer(
      lData = list(Mapped_SUBJ = data.frame(subjid = "01", sex = "F")),
      lSettings = lSettings,
      strOutputDir = tempdir()
    ),
    "Mapped_AE"
  )

  bad_data <- MakeAeExplorerExampleData()
  bad_data$Mapped_AE$mdrpt_nsv <- NULL
  expect_error(
    Report_AE_Explorer(
      lData = bad_data,
      lSettings = lSettings,
      strOutputDir = tempdir()
    ),
    "mdrpt_nsv"
  )
})
