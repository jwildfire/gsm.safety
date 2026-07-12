# Render the AE Timelines report from bundled example data.
#
# Usage:
#   Rscript inst/examples/ae-timelines.R [output_dir]
#
# The report is written to `output_dir` (default: tempdir()) as
# ae_timelines.html via the ae_timelines report workflow.

if (!requireNamespace("gsm.safety", quietly = TRUE)) {
  stop(
    "gsm.safety must be installed (or loaded with devtools::load_all()).",
    call. = FALSE
  )
}
if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Package 'yaml' is required to run this example.", call. = FALSE)
}

strOutputDir <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(strOutputDir)) {
  strOutputDir <- tempdir()
}
if (!dir.exists(strOutputDir)) {
  dir.create(strOutputDir, recursive = TRUE)
}

lWorkflow <- yaml::read_yaml(
  system.file(
    "workflow", "3_reports", "ae_timelines.yaml",
    package = "gsm.safety"
  )
)
dfResults <- gsm.safety::ExampleData("adae")

strWd <- setwd(strOutputDir)
strReportPath <- tryCatch(
  gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  ),
  finally = setwd(strWd)
)

cat("AE Timelines report written to:", strReportPath, "\n")
