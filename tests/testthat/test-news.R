# Guards for NEWS.md (#110).
#
# NEWS.md is always current on dev: one user-facing bullet per feature linking
# its issue and its pull request. The review fixes of the release candidate first
# landed linking the issue alone, which leaves a reader one hop short of the
# diff; every bullet under "Also in this release" that cites an issue is checked
# here for the pull request link beside it.

strNewsMd <- function() {
  strPath <- testthat::test_path("..", "..", "NEWS.md")
  if (!file.exists(strPath)) {
    strPath <- system.file("NEWS.md", package = "gsm.safety")
  }
  skip_if_not(nzchar(strPath) && file.exists(strPath), "NEWS.md not available in this check context")
  strPath
}

chrReleaseBullets <- function(strVersion, strHeading) {
  chrLines <- readLines(strNewsMd(), warn = FALSE)
  nStart <- grep(paste0("^# gsm.safety v", strVersion, "\\b"), chrLines)
  expect_length(nStart, 1)
  chrSection <- chrLines[seq(nStart, length(chrLines))]
  nEnd <- grep("^# gsm.safety v", chrSection)[2]
  if (!is.na(nEnd)) chrSection <- chrSection[seq_len(nEnd - 1)]
  nHeading <- grep(paste0("^## ", strHeading, "$"), chrSection)
  expect_length(nHeading, 1)
  chrBlock <- chrSection[seq(nHeading + 1, length(chrSection))]
  nNext <- grep("^## ", chrBlock)[1]
  if (!is.na(nNext)) chrBlock <- chrBlock[seq_len(nNext - 1)]
  grep("^- ", chrBlock, value = TRUE)
}

test_that("every v1.2.0 review-fix NEWS bullet links its issue and its pull request (#110)", {
  chrBullets <- chrReleaseBullets("1.2.0", "Also in this release")
  chrCited <- grep("gsm.safety/issues/[0-9]+", chrBullets, value = TRUE)
  expect_gte(length(chrCited), 4)

  for (strBullet in chrCited) {
    expect_match(strBullet, "gsm.safety/pull/[0-9]+", info = substr(strBullet, 1, 60))
  }

  lPairs <- list(c("96", "97"), c("99", "101"), c("102", "105"), c("103", "104"))
  for (chrPair in lPairs) {
    strBullet <- grep(paste0("/issues/", chrPair[1], "\\)"), chrBullets, value = TRUE)
    expect_length(strBullet, 1)
    expect_match(strBullet, paste0("/pull/", chrPair[2], "\\)"), fixed = FALSE)
  }
})

test_that("every v1.2.0 FDA phase 0 NEWS bullet links its issue, its pull request and the hub requirement (#127)", {
  chrBullets <- chrReleaseBullets("1.2.0", "FDA ST&F phase 0")
  chrCited <- grep("gsm.safety/issues/[0-9]+", chrBullets, value = TRUE)
  expect_length(chrCited, 4)

  for (strBullet in chrCited) {
    expect_match(strBullet, "gsm.safety/pull/[0-9]+", info = substr(strBullet, 1, 60))
    expect_match(strBullet, "obot.roadmap/issues/9\\)", info = substr(strBullet, 1, 60))
  }

  lPairs <- list(c("77", "83"), c("79", "84"), c("80", "85"), c("78", "86"))
  for (chrPair in lPairs) {
    strBullet <- grep(paste0("/issues/", chrPair[1], "\\)"), chrBullets, value = TRUE)
    expect_length(strBullet, 1)
    expect_match(strBullet, paste0("/pull/", chrPair[2], "\\)"), fixed = FALSE)
  }
})

test_that("the v1.2.0 NEWS bullets describe the collision guard and the criterion text as shipped (#137)", {
  # The #102 bullet once said a frame carrying AbnormalityDirection keeps it;
  # the guard refuses it, and the (#102) test asserts the error.
  chrFixes <- chrReleaseBullets("1.2.0", "Also in this release")
  strCollision <- grep("/issues/102\\)", chrFixes, value = TRUE)
  expect_length(strCollision, 1)
  expect_no_match(strCollision, "keeps it")
  expect_match(strCollision, "AbnormalityDirection")
  expect_match(strCollision, "refused")

  # Only FDA_AbnormalityLevels carries the printed criterion text.
  chrFeatures <- chrReleaseBullets("1.2.0", "FDA ST&F phase 0")
  strData <- grep("/issues/77\\)", chrFeatures, value = TRUE)
  expect_length(strData, 1)
  expect_no_match(strData, "Every row carries[^.;]*criterion text")
  expect_match(strData, "abnormality-level rows also carry each criterion")
})

test_that("dev carries one unreleased section, v1.2.0, that leads with the two clinical corrections (#151)", {
  chrLines <- readLines(strNewsMd(), warn = FALSE)
  expect_identical(
    grep("^# gsm.safety v[0-9.]+ \\(Upcoming\\)$", chrLines, value = TRUE),
    "# gsm.safety v1.2.0 (Upcoming)"
  )
  expect_false(any(grepl("^# gsm.safety v1\\.[345]\\.0", chrLines)))
  expect_identical(as.character(utils::packageVersion("gsm.safety")), "1.2.0")

  nStart <- grep("^# gsm.safety v1\\.2\\.0", chrLines)
  chrSection <- chrLines[seq(nStart, length(chrLines))]
  nEnd <- grep("^# gsm.safety v", chrSection)[2]
  chrSection <- chrSection[seq_len(nEnd - 1)]
  expect_identical(
    grep("^## ", chrSection, value = TRUE),
    c(
      "## Two clinical figures change", "## Four new widgets", "## The census rebuild",
      "## FDA ST&F phase 0", "## Worth knowing about the widgets", "## Also in this release"
    )
  )
  # The corrections keep their measured figures: the table of what moves and the eDISH counts.
  expect_true(any(grepl("^\\| Deaths \\| 4 \\| \\*\\*13\\*\\* \\|", chrSection)))
  expect_true(any(grepl("293 participants with 71 excluded", chrSection, fixed = TRUE)))
  expect_match(
    grep("^\\*\\*See it move:\\*\\*", chrSection, value = TRUE)[1],
    "https://jwildfire.github.io/obot.roadmap/reports/gs-v1.2-demo/",
    fixed = TRUE
  )
})
