# Render the Hepatic ALT Waterfall report from bundled example data.
#
# Usage:
#   Rscript inst/examples/hep-waterfall.R [output_dir]
#
# The report is written to `output_dir` (default: tempdir()) as
# hep_waterfall.html via the hep_waterfall report workflow.

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
    "workflow", "4_modules", "hep_waterfall.yaml",
    package = "gsm.safety"
  )
)
dfResults <- gsm.safety::ExampleData("adbds_abnbl")

strWd <- setwd(strOutputDir)
strReportPath <- tryCatch(
  gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults)
  ),
  finally = setwd(strWd)
)

cat("Hepatic ALT Waterfall report written to:", strReportPath, "\n")
