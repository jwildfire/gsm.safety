# Render the Time-to-Event report from bundled example data.
#
# Usage:
#   Rscript inst/examples/time-to-event.R [output_dir]
#
# The report is written to `output_dir` (default: tempdir()) as
# time_to_event.html via the time_to_event report workflow.

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
    "workflow", "4_modules", "time_to_event.yaml",
    package = "gsm.safety"
  )
)

# The bundled adverse events carry one all-blank placeholder row per
# participant with no events, so the AE renderers' denominator covers the whole
# safety population. Those rows are not events, and this chart takes its
# denominator from the population frame instead.
dfAE <- gsm.safety::ExampleData("adae")
dfResults <- dfAE[nzchar(dfAE$AEDECOD), ]
dfPopulation <- gsm.safety::ExampleData("adsl")

strWd <- setwd(strOutputDir)
strReportPath <- tryCatch(
  gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(dfResults = dfResults, dfPopulation = dfPopulation)
  ),
  finally = setwd(strWd)
)

cat("Time-to-Event report written to:", strReportPath, "\n")
