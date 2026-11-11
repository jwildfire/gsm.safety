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
  # What is knowingly left out cites its issues and has no pull request yet.
  chrBullets <- grep("knowingly not in this release", chrBullets, value = TRUE, invert = TRUE)
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

test_that("the v1.2.0 FDA phase 0 NEWS bullet links each issue, its pull request and the hub requirement (#127)", {
  chrFeatures <- chrReleaseBullets("1.2.0", "What's new")
  strBullet <- grep("/issues/77\\)", chrFeatures, value = TRUE)
  expect_length(strBullet, 1)
  expect_match(strBullet, "obot.roadmap/issues/9\\)")

  lPairs <- list(c("77", "83"), c("79", "84"), c("80", "85"), c("78", "86"))
  for (chrPair in lPairs) {
    expect_match(strBullet, paste0("/issues/", chrPair[1], "\\), PR \\[#", chrPair[2], "\\]"))
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

  # Only FDA_AbnormalityLevels carries the printed criterion text; the notes
  # must not say every row does (the detail is on the demo page).
  chrFeatures <- chrReleaseBullets("1.2.0", "What's new")
  strData <- grep("/issues/77\\)", chrFeatures, value = TRUE)
  expect_length(strData, 1)
  expect_no_match(strData, "Every row carries[^.;]*criterion text")
})

test_that("dev carries one unreleased section, v1.2.0, in the release-notes shape, led by the death count (#151)", {
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
    c("## What's new", "## Deprecated", "## Removed", "## Also in this release", "## Tests and provenance")
  )
  # The death count leads, with the figures it moves between (#168 re-measured
  # them on gsm.core 1.3.2).
  chrNew <- chrReleaseBullets("1.2.0", "What's new")
  expect_match(chrNew[1], "12 of 754 where `SafetyCensus()` reported 2", fixed = TRUE)
  expect_match(
    grep("^\\*\\*See it move:\\*\\*", chrSection, value = TRUE)[1],
    "https://jwildfire.github.io/obot.roadmap/reports/gsm-safety-v1.2.0-demo/",
    fixed = TRUE
  )
})

test_that("every v1.2.0 What's new bullet links its hub requirement, and the toggle is counted right (#171)", {
  chrNew <- chrReleaseBullets("1.2.0", "What's new")
  for (strBullet in chrNew) {
    expect_match(strBullet, "obot.roadmap/issues/[0-9]+", info = substr(strBullet, 1, 60))
  }
  # The hep waterfall's contract has no x_axis: four widgets take the toggle.
  strToggle <- grep("Study day toggle", chrNew, value = TRUE)
  expect_length(strToggle, 1)
  expect_match(strToggle, "Four widgets", fixed = TRUE)
  expect_no_match(strToggle, "hep waterfall, ", fixed = TRUE)
})
