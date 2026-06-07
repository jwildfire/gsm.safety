widget_gallery_project_root <- function(required = "README.md") {
  candidates <- c(
    Sys.getenv("GITHUB_WORKSPACE", ""),
    getwd(),
    file.path(getwd(), ".."),
    file.path(getwd(), "..", ".."),
    file.path(getwd(), "..", "00_pkg_src", "gsm.safety"),
    file.path(getwd(), "..", "..", "..")
  )
  candidates <- unique(normalizePath(candidates[nzchar(candidates)], mustWork = FALSE))
  matches <- candidates[file.exists(file.path(candidates, required))]

  if (!length(matches)) {
    skip(paste("source checkout artifact is unavailable:", required))
  }

  matches[[1]]
}

test_that("README widget gallery links every supported report with thumbnail assets (#28)", {
  root <- widget_gallery_project_root("README.md")
  readme <- readLines(file.path(root, "README.md"), warn = FALSE)
  readme_text <- paste(readme, collapse = "\n")

  widgets <- c(
    "ae-explorer",
    "ae-timelines",
    "hep-explorer",
    "paneled-outlier-explorer",
    "safety-delta-delta",
    "safety-histogram",
    "safety-outlier-explorer",
    "safety-results-over-time",
    "safety-shift-plot"
  )

  examples <- c(
    "Example_AE_Explorer_Workflow.html",
    "Example_AE_Timelines_Workflow.html",
    "Example_HepExplorer_Workflow.html",
    "Example_PaneledOutlierExplorer_Workflow.html",
    "Example_SafetyDeltaDelta_Workflow.html",
    "Example_SafetyHistogram_Workflow.html",
    "Example_SafetyOutlierExplorer_Workflow.html",
    "Example_SafetyResultsOverTime_Workflow.html",
    "Example_SafetyShiftPlot_Workflow.html"
  )

  for (widget in widgets) {
    expect_true(
      file.exists(file.path(root, "man", "figures", "widgets", paste0(widget, ".svg"))),
      info = widget
    )
    expect_true(
      grepl(paste0("man/figures/widgets/", widget, ".svg"), readme_text, fixed = TRUE),
      info = widget
    )
  }

  for (example in examples) {
    expect_true(
      grepl(paste0("examples/", example), readme_text, fixed = TRUE),
      info = example
    )
  }
})


test_that("thumbnail capture script documents PR-preview PNG replacement path (#28)", {
  root <- widget_gallery_project_root(file.path("tools", "capture-widget-thumbnails.mjs"))
  script <- readLines(file.path(root, "tools", "capture-widget-thumbnails.mjs"), warn = FALSE)
  script_text <- paste(script, collapse = "\n")
  readme_text <- paste(readLines(file.path(root, "README.md"), warn = FALSE), collapse = "\n")

  expect_true(grepl("GSM_SAFETY_WIDGET_BASE_URL", script_text, fixed = TRUE))
  expect_true(grepl("man/figures/widgets", script_text, fixed = TRUE))
  expect_true(grepl(".png", script_text, fixed = TRUE))
  expect_true(grepl("GSM_SAFETY_WIDGET_BASE_URL=<preview-url>", readme_text, fixed = TRUE))
  expect_true(grepl("switch the gallery image paths from `.svg` to `.png`", readme_text, fixed = TRUE))
})
