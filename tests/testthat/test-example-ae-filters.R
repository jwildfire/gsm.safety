# The example adverse-event filters (#139).
#
# ExampleData("adae") carries one all-blank placeholder row per AE-free
# participant so the AE renderers' denominator covers the whole population.
# The examples that want actual events drop those rows. nzchar(NA) is TRUE,
# so a filter on nzchar() alone keeps a placeholder whose term arrives as NA;
# every site names the missing case as well.

chrAeFilterFiles <- function() {
  c(
    "R/Widget_ParticipantProfile.R",
    "R/Widget_TimeToEvent.R",
    "inst/examples/participant-profile.R",
    "inst/examples/time-to-event.R",
    "pkgdown/menus/examples/Example_ParticipantProfile.Rmd",
    "pkgdown/menus/examples/Example_TimeToEvent.Rmd",
    "tests/testthat/test-participant-profile.R",
    "tests/testthat/test-time-to-event.R"
  )
}

test_that("no example AE filter drops placeholder rows on nzchar() alone (#139)", {
  chrFiles <- chrAeFilterFiles()
  chrPaths <- testthat::test_path("..", "..", chrFiles)
  skip_if_not(all(file.exists(chrPaths)), "source tree not available in this check context")
  for (i in seq_along(chrFiles)) {
    chrLines <- readLines(chrPaths[i], warn = FALSE)
    chrFilters <- grep("nzchar(dfAE$AEDECOD)", chrLines, fixed = TRUE, value = TRUE)
    expect_gte(length(chrFilters), 1, label = chrFiles[i])
    for (strLine in chrFilters) {
      expect_match(strLine, "!is.na(dfAE$AEDECOD) & nzchar(dfAE$AEDECOD)", fixed = TRUE, info = chrFiles[i])
    }
  }
})

test_that("the example AE filter drops a placeholder row whether its term is blank or missing (#139)", {
  dfAE <- data.frame(
    USUBJID = c("a", "b", "c", "d"),
    AEDECOD = c("HEADACHE", "", NA, "NAUSEA"),
    stringsAsFactors = FALSE
  )
  dfEvents <- dfAE[!is.na(dfAE$AEDECOD) & nzchar(dfAE$AEDECOD), ]
  expect_identical(dfEvents$AEDECOD, c("HEADACHE", "NAUSEA"))
  # nzchar() alone is the trap the sites avoid.
  expect_identical(nrow(dfAE[nzchar(dfAE$AEDECOD), ]), 3L)
  # On the shipped data the two spellings collapse to the same 37 placeholders.
  dfShipped <- ExampleData("adae")
  dfShippedEvents <- dfShipped[!is.na(dfShipped$AEDECOD) & nzchar(dfShipped$AEDECOD), ]
  expect_false(any(is.na(dfShippedEvents$AEDECOD) | dfShippedEvents$AEDECOD == ""))
  expect_identical(nrow(dfShipped) - nrow(dfShippedEvents), 37L)
})
