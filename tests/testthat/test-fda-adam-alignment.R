# The ADaM to Mapped_* alignment note (#80, hub obot.roadmap#9).
#
# design/fda-adam-alignment.md is repository content (design/ is
# .Rbuildignore'd), so these tests skip under R CMD check and run under
# devtools::test(). The note's own check is its tables: every needed column
# carries exactly one of the four states, every non-found row carries a
# decision, and the summary adds up to the domain tables.

strNotePath <- function() {
  strPath <- testthat::test_path("..", "..", "design", "fda-adam-alignment.md")
  skip_if_not(file.exists(strPath), "design/fda-adam-alignment.md not available in this check context")
  strPath
}

NoteSections <- function() {
  chrLines <- readLines(strNotePath(), warn = FALSE)
  nHeading <- grep("^## ", chrLines)
  lSections <- list()
  for (i in seq_along(nHeading)) {
    nEnd <- if (i < length(nHeading)) nHeading[i + 1] - 1 else length(chrLines)
    lSections[[sub("^## ", "", chrLines[nHeading[i]])]] <- chrLines[nHeading[i]:nEnd]
  }
  lSections
}

TableRows <- function(chrLines) {
  chrRows <- chrLines[grepl("^\\| `?[A-Za-z]", chrLines) & !grepl("^\\| ADaM variable|^\\| Domain|^\\| Role", chrLines)]
  lapply(strsplit(chrRows, "(?<!\\\\)\\|", perl = TRUE), function(chr) trimws(chr[-1]))
}

CHR_DOMAINS <- c("ADSL", "ADAE", "ADLB", "ADVS")
CHR_STATES <- c("found", "mapped", "derived", "missing")

test_that("the alignment note covers the four domains and ends with the column contract (#80)", {
  lSections <- NoteSections()
  for (strDomain in CHR_DOMAINS) {
    expect_true(strDomain %in% names(lSections), info = strDomain)
  }
  expect_true("Summary" %in% names(lSections))
  expect_true("The column contract for phase 1" %in% names(lSections))
  expect_match(paste(readLines(strNotePath(), warn = FALSE), collapse = "\n"), "This note was drafted by Claude Code", fixed = TRUE)
})

test_that("every needed column carries exactly one of the four states (#80)", {
  lSections <- NoteSections()
  for (strDomain in CHR_DOMAINS) {
    lRows <- TableRows(lSections[[strDomain]])
    expect_gt(length(lRows), 5, label = strDomain)
    for (lRow in lRows) {
      expect_identical(length(lRow), 6L, info = paste(strDomain, lRow[[1]]))
      expect_true(lRow[[5]] %in% CHR_STATES, info = paste(strDomain, lRow[[1]], "state:", lRow[[5]]))
    }
  }
})

test_that("every mapped, derived or missing column carries a decision, and nothing is blocked (#80)", {
  lSections <- NoteSections()
  for (strDomain in CHR_DOMAINS) {
    for (lRow in TableRows(lSections[[strDomain]])) {
      if (lRow[[5]] != "found") {
        expect_gt(nchar(lRow[[6]]), 6, label = paste(strDomain, lRow[[1]], "decision")) # "As ADLB." is a decision by reference
      }
    }
  }
  strText <- paste(readLines(strNotePath(), warn = FALSE), collapse = "\n")
  expect_no_match(strText, "`blocked` question:", fixed = TRUE)
})

test_that("the summary table adds up to the domain tables (#80)", {
  lSections <- NoteSections()
  lSummary <- TableRows(lSections[["Summary"]])
  names(lSummary) <- vapply(lSummary, `[[`, character(1), 1)
  nTotal <- setNames(rep(0L, 5), c("needed", CHR_STATES))
  for (strDomain in CHR_DOMAINS) {
    chrStates <- vapply(TableRows(lSections[[strDomain]]), `[[`, character(1), 5)
    nCounts <- c(needed = length(chrStates), table(factor(chrStates, levels = CHR_STATES)))
    lRow <- lSummary[[strDomain]]
    expect_identical(as.integer(lRow[2:6]), unname(as.integer(nCounts)), info = strDomain)
    nTotal <- nTotal + nCounts
  }
  expect_identical(as.integer(lSummary[["Total"]][2:6]), unname(as.integer(nTotal)))
  expect_identical(unname(nTotal[["needed"]]), 51L)
})

test_that("the column contract names a default in the example data's spelling for every role (#80)", {
  lSections <- NoteSections()
  lRows <- TableRows(lSections[["The column contract for phase 1"]])
  chrRoles <- vapply(lRows, `[[`, character(1), 1)
  for (strRole in c("participant", "parameter", "value", "unit", "upper normal", "visit", "treatment arm")) {
    expect_true(strRole %in% chrRoles, info = strRole)
  }
  chrDefaults <- gsub("`", "", vapply(lRows, `[[`, character(1), 2))
  chrDefaults <- sub(" .*$", "", chrDefaults)
  chrExample <- names(ExampleData("adbds"))
  for (strDefault in intersect(chrDefaults, c("USUBJID", "TEST", "STRESN", "STRESU", "STNRLO", "STNRHI", "VISIT", "VISITNUM", "SEX", "ARM"))) {
    expect_true(strDefault %in% chrExample, info = strDefault)
  }
})
