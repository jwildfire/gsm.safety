# Reading the qualification records, in every context the suite runs in (#63).
#
# The records are installed content - inst/qualification/ - rather than
# repository content, and that is the whole point. R CMD check builds the
# package tarball; the records used to live in design/, which is
# .Rbuildignore'd, so every check that read one skipped in the one context
# where the merge is gated. A recorded check that cannot be read where checking
# happens is a check that cannot fail there.
#
# Nothing in this file ever skips. A record that cannot be found is not an
# unavailable context - it is the failure this layer exists to catch.

CHR_QUALIFICATION_RECORDS <- c(
  "death-count-qualification.md",
  "census-metrics-qualification.md",
  "census-report-qualification.md"
)

QualificationRecordPath <- function(strFile) {
  system.file("qualification", strFile, package = "gsm.safety")
}

QualificationRecord <- function(strFile) {
  strPath <- QualificationRecordPath(strFile)
  bFound <- nzchar(strPath) && file.exists(strPath)
  expect_true(
    bFound,
    label = paste0(
      "inst/qualification/", strFile,
      " is installed with the package and readable here"
    )
  )
  if (!bFound) {
    return(character(0))
  }
  readLines(strPath, warn = FALSE, encoding = "UTF-8")
}

# A markdown table, found by a pattern on its header row and read down to the
# first line that is not a row. Tables are located by their header rather than
# by scanning the whole file for row patterns because these records carry
# several tables that share row labels - "Enrolled" is a row in three of them -
# and a figure compared against the wrong table is not a check.
QualificationTable <- function(chrLines, strHeader, strFile) {
  iHeader <- grep(strHeader, chrLines)
  expect_identical(
    length(iHeader), 1L,
    info = paste0(strFile, " has exactly one table headed ", strHeader)
  )
  if (length(iHeader) != 1L) {
    return(list())
  }

  lRows <- list()
  i <- iHeader + 2L # the header row, then the |---|---| separator
  while (i <= length(chrLines) && grepl("^[|]", chrLines[[i]])) {
    lRows[[length(lRows) + 1L]] <- QualificationCells(chrLines[[i]])
    i <- i + 1L
  }
  expect_gt(length(lRows), 0)
  lRows
}

QualificationCells <- function(strRow) {
  chrCells <- trimws(strsplit(strRow, "|", fixed = TRUE)[[1]])
  chrCells[nzchar(chrCells)]
}

# One row of a table, found by a pattern on its first cell. A row that is
# renamed or removed fails by name here rather than dropping silently out of
# the comparison, which is the shape of the failure this whole layer is for.
QualificationRow <- function(lTable, strPattern, strFile, strLabel) {
  bMatch <- vapply(lTable, function(chrCells) {
    length(chrCells) > 0L && grepl(strPattern, chrCells[[1]])
  }, logical(1))
  expect_identical(
    sum(bMatch), 1L,
    info = paste0(strFile, " has exactly one row for ", strLabel)
  )
  if (sum(bMatch) != 1L) {
    return(character(0))
  }
  lTable[[which(bMatch)]]
}

# The records are wrapped prose, so a sentence is not a line. Prose checks read
# the file as one string with the blockquote markers and the wrapping removed.
QualificationProse <- function(chrLines) {
  paste(gsub("^[>][ ]?", "", chrLines), collapse = " ")
}

# The first number in a cell, with the record's formatting removed: thousands
# separators, bold, inline code, and the trailing detail some cells carry
# ("3 (`S42425`, ...)"). A cell that states no figure - *blank*, *no domain* -
# reads as NA rather than as zero, because those are different claims.
QualificationNumber <- function(strCell) {
  if (length(strCell) != 1L || is.na(strCell)) {
    return(NA_real_)
  }
  strClean <- gsub("[`*]", "", strCell)
  strClean <- gsub("(?<=[0-9]),(?=[0-9])", "", strClean, perl = TRUE)
  strMatch <- regmatches(strClean, regexpr("-?[0-9]+([.][0-9]+)?", strClean))
  if (!length(strMatch)) {
    return(NA_real_)
  }
  as.numeric(strMatch)
}

# One comparison, named so that a failure says which record and which figure
# disagrees - not which line of which test file.
ExpectRecordFigure <- function(strFile, strFigure, nRecord, nQualified,
                               tolerance = testthat::testthat_tolerance()) {
  expect_equal(
    nRecord, as.numeric(nQualified),
    tolerance = tolerance,
    info = paste0(strFile, " records ", strFigure)
  )
}

# The failure being fixed here was silent: a check that did not run, and so
# could not fail, in the context that gates the merge. Absence from a skip list
# is not evidence that a check ran, so every document-agreement block says on
# the way out what it compared. R CMD check writes the test output to
# testthat.Rout and CI prints it, which makes "it ran" readable in the log
# rather than inferred from what is missing.
RecordDocumentAgreement <- function(strFile, nFigures) {
  cat(sprintf(
    "[QUALIFICATION] %s: %d recorded figures compared with the qualified values\n",
    strFile, nFigures
  ))
  invisible(nFigures)
}
