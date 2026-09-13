# The consolidation (#151) ships the census rebuild and the parity catch-up in
# v1.2.0. Text written while they were the v1.3.0 to v1.5.0 candidates must not
# date them otherwise, and nothing may describe SafetyCensus() as awaiting a
# rebuild that has shipped (#153).

strSourceFile <- function(...) {
  strPath <- testthat::test_path("..", "..", ...)
  skip_if_not(
    file.exists(strPath),
    paste(file.path(...), "not available in this check context")
  )
  strPath
}

chrUnreleasedNews <- function() {
  strPath <- testthat::test_path("..", "..", "NEWS.md")
  if (!file.exists(strPath)) {
    strPath <- system.file("NEWS.md", package = "gsm.safety")
  }
  skip_if_not(nzchar(strPath) && file.exists(strPath), "NEWS.md not available in this check context")
  chrLines <- readLines(strPath, warn = FALSE)
  nStart <- grep("^# gsm.safety v[0-9.]+ \\(Upcoming\\)$", chrLines)
  expect_length(nStart, 1)
  chrSection <- chrLines[seq(nStart, length(chrLines))]
  nEnd <- grep("^# gsm.safety v", chrSection)[2]
  chrSection[seq_len(nEnd - 1)]
}

test_that("nothing shipped in v1.2.0 is dated to a later release, and SafetyCensus() is described as rebuilt (#153)", {
  strStale <- "v1\\.[345]\\.0"

  # The roxygen and the rendered help page of the rebuilt function.
  expect_false(any(grepl(strStale, readLines(strSourceFile("R", "SafetyCensus.R"), warn = FALSE))))
  strPkgDir <- testthat::test_path("..", "..")
  lRd <- if (file.exists(file.path(strPkgDir, "man", "SafetyCensus.Rd"))) {
    tools::Rd_db(dir = strPkgDir)
  } else {
    tools::Rd_db("gsm.safety")
  }
  # Rd2txt wraps lines, so collapse the whitespace before matching.
  strHelp <- gsub("\\s+", " ", paste(utils::capture.output(tools::Rd2txt(lRd[["SafetyCensus.Rd"]])), collapse = " "))
  expect_false(grepl(strStale, strHelp))
  expect_match(strHelp, "Until v1.2.0 this function did its own arithmetic", fixed = TRUE)

  # The qualification records ship inside the package.
  chrRecords <- list.files(
    system.file("qualification", package = "gsm.safety"),
    pattern = "\\.md$", full.names = TRUE
  )
  expect_gte(length(chrRecords), 3)
  for (strRecord in chrRecords) {
    expect_false(
      any(grepl(strStale, readLines(strRecord, warn = FALSE))),
      info = basename(strRecord)
    )
  }

  # The unreleased notes: the only v1.3.0 to v1.5.0 left are safety.viz bundle versions.
  chrNews <- chrUnreleasedNews()
  chrDated <- grep(strStale, chrNews, value = TRUE)
  expect_true(all(grepl("safety.viz", chrDated, fixed = TRUE)), info = paste(substr(chrDated, 1, 80), collapse = " | "))
  expect_true(any(grepl("^\\| Figure \\| Before v1\\.2\\.0 \\| Now \\|", chrNews)))
  expect_false(any(grepl("stay unwrapped", chrNews, fixed = TRUE)))
  expect_true(any(grepl("The parity allowlist is empty", chrNews, fixed = TRUE)))
  expect_true(any(grepl("DEMO-301", chrNews, fixed = TRUE)))
})

test_that("the reference index and the qualification script describe the rebuilt census (#153)", {
  chrPkgdown <- readLines(strSourceFile("_pkgdown.yml"), warn = FALSE)
  expect_false(any(grepl("unchanged until step four", chrPkgdown, fixed = TRUE)))
  expect_true(any(grepl("reads the figures they published", chrPkgdown, fixed = TRUE)))

  chrScript <- readLines(strSourceFile("tools", "qualify-census-metrics.R"), warn = FALSE)
  nCall <- grep("What SafetyCensus() reports for the same study today", chrScript, fixed = TRUE)
  expect_length(nCall, 1)
  chrCall <- chrScript[seq(nCall, min(nCall + 12, length(chrScript)))]
  expect_true(any(grepl("dfDeath = lMapped$Mapped_Death", chrCall, fixed = TRUE)))
  expect_true(any(grepl("dfRandomization = lMapped$Mapped_Randomization", chrCall, fixed = TRUE)))
})
