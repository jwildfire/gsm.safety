# Render the Participant Profile report from bundled example data.
#
# Usage:
#   Rscript inst/examples/participant-profile.R [output_dir]
#
# The report is written to `output_dir` (default: tempdir()) as
# participant_profile.html via the participant_profile report workflow.

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
    "workflow", "4_modules", "participant_profile.yaml",
    package = "gsm.safety"
  )
)

dfResults <- gsm.safety::ExampleData("adbds")
dfAE <- gsm.safety::ExampleData("adae")
dfAE <- dfAE[nzchar(dfAE$AEDECOD), ]

# The profile renders a cohort someone chose; in a live report that list comes
# from a flagging metric. Here it is three participants of the pilot study.
chrParticipants <- c("01-701-1015", "01-701-1023", "01-701-1028")

strWd <- setwd(strOutputDir)
strReportPath <- tryCatch(
  gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(
      dfResults = dfResults,
      dfAE = dfAE,
      chrParticipants = chrParticipants
    )
  ),
  finally = setwd(strWd)
)

cat("Participant Profile report written to:", strReportPath, "\n")
