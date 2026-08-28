# The offline half of the workflow-reference guard (#55).
#
# Five workflows here delegate to reusable workflows in another organisation.
# When `gsm.utils` and `qcthat` moved from `Gilead-BioStats` to `Gilead-Public`
# on 2026-08-04, every `uses:` in this directory still named the old one.
# GitHub follows a transfer redirect for an action called from a step - which is
# why R-CMD-check never noticed - but not for a reusable workflow called from a
# job, which has to be resolved when the workflow file is parsed. A caller that
# cannot be resolved never reaches the point of having jobs, so the run fails
# with zero jobs, raises no check run, and appears on a pull request as nothing
# at all. Four workflows failed that way for three weeks, two of them the checks
# that speak to whether what ships is what was qualified, and PR #68 - a
# clinical release candidate - showed six checks and six passes throughout.
#
# The durable guard is the compliance check in CI: `workflow-template-check`
# compares each file's header against the upstream manifest, so an organisation
# that moves again goes red there. This is the fast local half, in the same
# split the safety.viz parity guard already uses - and it is the half that names
# the failure in the terms it actually took, which a version-header comparison
# does not.
#
# These read the repository tree rather than installed content, so they are
# unavailable to `R CMD check`, which builds from a tarball with `.github`
# removed by `.Rbuildignore`. They do run under `devtools::test()` and in the
# qcthat job, which checks out the repository.

WorkflowFiles <- function() {
  strDir <- testthat::test_path("..", "..", ".github", "workflows")
  if (!dir.exists(strDir)) {
    return(character(0))
  }
  list.files(strDir, pattern = "[.]ya?ml$", full.names = TRUE)
}

# Every `uses:` in the directory, as owner/rest.
WorkflowUses <- function(chrFiles) {
  chrLines <- unlist(lapply(chrFiles, function(strFile) {
    chrFileLines <- readLines(strFile, warn = FALSE)
    chrMatched <- grep("^\\s*-?\\s*uses:\\s*\\S+", chrFileLines, value = TRUE)
    if (!length(chrMatched)) {
      return(character(0))
    }
    stats::setNames(
      trimws(sub("^\\s*-?\\s*uses:\\s*", "", chrMatched)),
      rep(basename(strFile), length(chrMatched))
    )
  }))
  if (is.null(chrLines)) character(0) else chrLines
}

test_that("no workflow calls the organisation that no longer hosts it (#55)", {
  chrFiles <- WorkflowFiles()
  skip_if_not(length(chrFiles) > 0, ".github/workflows not available in this check context")

  chrUses <- WorkflowUses(chrFiles)
  expect_gt(length(chrUses), 0)

  chrStale <- chrUses[grepl("gilead-biostats", chrUses, ignore.case = TRUE)]
  expect_identical(
    unname(chrStale),
    character(0),
    label = paste(
      "References to Gilead-BioStats, which no longer hosts these:",
      paste(names(chrStale), chrStale, sep = " -> ", collapse = "; ")
    )
  )
})

test_that("every cross-repository reusable workflow names gilead-public (#55)", {
  chrFiles <- WorkflowFiles()
  skip_if_not(length(chrFiles) > 0, ".github/workflows not available in this check context")

  chrUses <- WorkflowUses(chrFiles)
  # The `uses:` form that is resolved at parse time, and so is the form that
  # takes a whole run down rather than one step: owner/repo/.github/workflows/x.
  chrCallers <- chrUses[grepl("/[.]github/workflows/", chrUses, fixed = FALSE)]
  expect_gt(length(chrCallers), 0)

  chrOwners <- tolower(sub("/.*$", "", chrCallers))
  chrWrong <- chrCallers[chrOwners != "gilead-public"]
  expect_identical(
    unname(chrWrong),
    character(0),
    label = paste(
      "Reusable-workflow calls naming an owner other than gilead-public:",
      paste(names(chrWrong), chrWrong, sep = " -> ", collapse = "; ")
    )
  )
})
