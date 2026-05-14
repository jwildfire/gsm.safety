test_that("all safetyCharts widget report workflows are workr-shaped", {
  workflow_ids <- c(
    "ae_explorer",
    "ae_timelines",
    "hep_explorer",
    "nep_explorer",
    "paneled_outlier_explorer",
    "safety_delta_delta",
    "safety_histogram",
    "safety_outlier_explorer",
    "safety_results_over_time",
    "safety_shift_plot"
  )

  for (id in workflow_ids) {
    report_path <- system.file(
      "workflow", "3_reports", paste0(id, ".yaml"),
      package = "gsm.safety"
    )
    if (!nzchar(report_path)) {
      candidates <- c(
        file.path("inst", "workflow", "3_reports", paste0(id, ".yaml")),
        file.path("..", "..", "inst", "workflow", "3_reports", paste0(id, ".yaml"))
      )
      report_path <- candidates[file.exists(candidates)][[1]]
    }

    expect_true(file.exists(report_path), info = id)
    report_text <- readLines(report_path, warn = FALSE)
    expect_true(any(grepl("Type: Report", report_text, fixed = TRUE)), info = id)
    expect_true(any(grepl(paste0("ID: ", id), report_text, fixed = TRUE)), info = id)
    expect_true(any(grepl("widgetName:", report_text, fixed = TRUE)), info = id)
    expect_true(any(grepl("widgetSettings:", report_text, fixed = TRUE)), info = id)
    expect_true(any(grepl("spec:", report_text, fixed = TRUE)), info = id)
    expect_true(any(grepl("steps:", report_text, fixed = TRUE)), info = id)
    expect_true(any(grepl("gsm.safety::RenderSafetyChartsWidget", report_text, fixed = TRUE)), info = id)
  }
})
