# Guards for CLAUDE.md (#81).
#
# CLAUDE.md is what a Claude Code session reads first: the commands to run, the
# conventions to follow, and the Standards block pointing at the obot hub. A
# file that names a script or a test that no longer exists sends a session down
# a dead path, so every path it cites is checked against the repository here.
#
# CLAUDE.md is .Rbuildignore'd, so these tests skip under R CMD check and run
# under devtools::test() — the same contract as the README and gallery tests.

strClaudeMd <- function() {
  strPath <- testthat::test_path("..", "..", "CLAUDE.md")
  skip_if_not(file.exists(strPath), "CLAUDE.md not available in this check context")
  strPath
}

test_that("CLAUDE.md carries the Standards block and names the requirement session (#81)", {
  chrLines <- readLines(strClaudeMd(), warn = FALSE)
  strText <- paste(chrLines, collapse = "\n")

  expect_true(any(grepl("^# Standards$", chrLines)))
  expect_match(strText, "The obot program's standards are mandatory here", fixed = TRUE)
  expect_match(strText, "jwildfire/obot.roadmap `docs/`", fixed = TRUE)
  expect_match(strText, "/requirement-session", fixed = TRUE)
})

test_that("CLAUDE.md names the commands a session runs (#81)", {
  strText <- paste(readLines(strClaudeMd(), warn = FALSE), collapse = "\n")

  for (strCommand in c("devtools::document()", "devtools::test()", "devtools::check()")) {
    expect_match(strText, strCommand, fixed = TRUE)
  }
})

test_that("every repository path CLAUDE.md cites exists (#81)", {
  strRoot <- testthat::test_path("..", "..")
  strText <- paste(readLines(strClaudeMd(), warn = FALSE), collapse = "\n")

  chrPaths <- c(
    "tools/check-safety-viz-parity.sh",
    "tests/testthat/test-safety-viz-parity.R",
    "tests/testthat/test-qcthat-convention.R",
    ".github/parity-allowlist.yaml",
    "inst/schema/",
    "inst/workflow/2_metrics/",
    "NEWS.md"
  )
  for (strPath in chrPaths) {
    expect_match(strText, strPath, fixed = TRUE, label = paste("CLAUDE.md cites", strPath))
    expect_true(file.exists(file.path(strRoot, strPath)), label = paste(strPath, "exists"))
  }
})
