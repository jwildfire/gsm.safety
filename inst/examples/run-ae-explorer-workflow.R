# Run the AE Explorer workr workflow against bundled example data.
#
# From an installed package:
#   source(system.file("examples", "run-ae-explorer-workflow.R", package = "gsm.safety"))
#
# From a source checkout:
#   source("inst/examples/run-ae-explorer-workflow.R")

if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Package 'yaml' is required to run this workflow example.", call. = FALSE)
}
if (!requireNamespace("workr", quietly = TRUE)) {
  stop("Package 'workr' is required to run this workflow example.", call. = FALSE)
}

workflow_path <- system.file("workflow", "3_reports", "ae_explorer.yaml", package = "gsm.safety")
if (!nzchar(workflow_path)) {
  workflow_path <- file.path("inst", "workflow", "3_reports", "ae_explorer.yaml")
}

lWorkflow <- yaml::read_yaml(workflow_path)
lData <- gsm.safety::MakeAeExplorerExampleData()

lReport <- workr::RunWorkflow(
  lWorkflow = lWorkflow,
  lData = lData,
  bReturnResult = TRUE
)

message("AE Explorer report written to: ", lReport$path)
lReport
