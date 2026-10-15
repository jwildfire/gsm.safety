# The FDA ST&F requirement matrix (#79, hub obot.roadmap#9).
#
# requirements/fda-stf.md is repository content, not package content (it is
# .Rbuildignore'd like CLAUDE.md and the README), so these tests skip under
# R CMD check and run under devtools::test().

strMatrixPath <- function() {
  strPath <- testthat::test_path("..", "..", "requirements", "fda-stf.md")
  skip_if_not(file.exists(strPath), "requirements/fda-stf.md not available in this check context")
  strPath
}

MatrixRows <- function() {
  chrLines <- readLines(strMatrixPath(), warn = FALSE)
  chrRows <- chrLines[grepl("^\\| FDA-", chrLines)]
  lCells <- lapply(strsplit(chrRows, "(?<!\\\\)\\|", perl = TRUE), function(chr) trimws(chr[-1]))
  chrID <- vapply(lCells, `[[`, character(1), 1)
  list(rows = chrRows, cells = lCells, ids = chrID)
}

test_that("the matrix carries a keyed row for each of the 22 figures (#79)", {
  l <- MatrixRows()
  chrFig <- l$ids[grepl("^FDA-FIG-", l$ids)]
  expect_identical(length(chrFig), 22L)
  expect_identical(chrFig, sprintf("FDA-FIG-%03d", 1:22))
})

test_that("every matrix ID matches the safety.viz extractor pattern and is unique (#79)", {
  l <- MatrixRows()
  expect_true(all(grepl("^[A-Z]{2,4}-[A-Z]+-[0-9]+[A-D]?$", l$ids)))
  expect_false(any(duplicated(l$ids)))
  expect_setequal(unique(sub("^FDA-([A-Z]+)-.*$", "\\1", l$ids)), c("FIG", "RULE"))
  # The requirement text is the third cell, as in safety.viz.
  for (lRow in l$cells) {
    expect_gt(nchar(lRow[[3]]), 40)
  }
})

test_that("every row names the guide version and the section it comes from (#79)", {
  l <- MatrixRows()
  for (i in seq_along(l$cells)) {
    strSource <- l$cells[[i]][[4]]
    expect_match(strSource, "IG v2.0", fixed = TRUE, info = l$ids[[i]])
    expect_match(strSource, "section[s]? [0-9]+\\.[0-9]", info = l$ids[[i]])
  }
})

test_that("every figure row carries an engine, its ADaM domains and a phase (#79)", {
  l <- MatrixRows()
  bFig <- grepl("^FDA-FIG-", l$ids)
  for (lRow in l$cells[bFig]) {
    expect_true(nzchar(lRow[[5]]), info = lRow[[1]]) # engine
    expect_match(lRow[[6]], "^AD[A-Z]{2}(, AD[A-Z]{2})*$", info = lRow[[1]]) # domains
    expect_true(nzchar(lRow[[7]]), info = lRow[[1]]) # safety.viz twin, or "none"
    expect_true(nzchar(lRow[[8]]), info = lRow[[1]]) # phase
  }
})

test_that("the phase 0 rules the Derive_* functions implement are keyed (#79)", {
  l <- MatrixRows()
  # ULN multiples, abnormality grading, extreme-value exclusion and its unit
  # matching: the rows the phase 0 derivations (gsm.safety#78) cite.
  for (strID in c("FDA-RULE-001", "FDA-RULE-002", "FDA-RULE-004", "FDA-RULE-005")) {
    expect_true(strID %in% l$ids, info = strID)
    expect_identical(l$cells[[which(l$ids == strID)]][[8]], "0")
  }
})

test_that("every FDA-RULE ID a test cites exists in the matrix (#79)", {
  l <- MatrixRows()
  chrTestFiles <- list.files(testthat::test_path(), pattern = "^test-.*[.][Rr]$", full.names = TRUE)
  chrCited <- unique(unlist(lapply(chrTestFiles, function(strFile) {
    chrText <- readLines(strFile, warn = FALSE)
    regmatches(chrText, gregexpr("FDA-(FIG|RULE)-[0-9]{3}", chrText))
  })))
  chrMissing <- setdiff(chrCited, l$ids)
  expect_identical(chrMissing, character(0), label = paste("cited but not in the matrix:", paste(chrMissing, collapse = ", ")))
})

test_that("the FDA-RULE-002 row distinguishes grade 0 from no grade, as Derive_AbnormalityLevel() does (#128)", {
  l <- MatrixRows()
  strRequirement <- l$cells[[which(l$ids == "FDA-RULE-002")]][[3]]
  # Grade 0 is a graded result that met no level; NA is a record the criteria
  # could not be applied to. The row is the source of record and must not
  # call both "no grade".
  expect_match(strRequirement, "is graded 0")
  expect_match(strRequirement, "has no grade \\(`NA`\\)")
  expect_no_match(strRequirement, "wrong side of the operator, or for a parameter the tables do not list, has no grade")
})
