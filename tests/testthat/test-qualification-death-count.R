# Qualifying the death count (#56, D0023).
#
# Passing tests are not the check. A test asserting that the code does what the
# code does would not have caught one of the defects this metric exists to fix.
# The count is therefore measured twice on the same study, by two routes that
# share no code:
#
#   Route B  the death records read directly out of the bundled study with base
#            R — no mapping package, no metric, no gsm helper.
#   Route A  the standard mapping into gsm.mapping's Mapped_Death, then the
#            saf0004 workflow end to end.
#
# The recorded result, the numbers below, and how to reproduce them outside the
# test suite are in design/death-count-qualification.md.

# Route B constants, measured 2026-08-21 against gsm.core 1.2.0's lSource.
N_ENROLLED <- 760L
N_DEATH_DOMAIN <- 12L # distinct participants with a death record
N_DISCONTINUATION <- 1L # distinct participants whose compreas is "Death"
N_UNION_ALL <- 13L # the two sources combined, before the enrolment anchor
N_UNION_ENROLLED <- 12L # the same union, restricted to enrolled participants

RouteB <- function() {
  # Deliberately base R. The point of a second route is that it shares no
  # implementation with the one being checked.
  lSource <- gsm.core::lSource
  dfSubjects <- lSource$Raw_SUBJ
  chrEnrolled <- unique(as.character(dfSubjects$subjid[dfSubjects$enrollyn == "Y"]))

  dfDeath <- lSource$Raw_Death
  chrDeathDomain <- unique(as.character(dfDeath$subjid[!is.na(dfDeath$death_dt)]))

  dfComp <- lSource$Raw_STUDCOMP
  chrDiscontinuation <- unique(as.character(
    dfComp$subjid[!is.na(dfComp$compreas) & dfComp$compreas == "Death"]
  ))

  chrUnion <- union(chrDeathDomain, chrDiscontinuation)
  list(
    Enrolled = chrEnrolled,
    DeathDomain = chrDeathDomain,
    Discontinuation = chrDiscontinuation,
    Union = chrUnion,
    UnionEnrolled = intersect(chrUnion, chrEnrolled)
  )
}

test_that("route B: the bundled study's death records read directly (#56)", {
  l <- RouteB()

  expect_identical(length(l$Enrolled), N_ENROLLED)
  expect_identical(length(l$DeathDomain), N_DEATH_DOMAIN)
  expect_identical(length(l$Discontinuation), N_DISCONTINUATION)
  # The two sources name entirely different participants on this study, which
  # is why the union is their sum rather than the larger of them.
  expect_identical(length(intersect(l$DeathDomain, l$Discontinuation)), 0L)
  expect_identical(length(l$Union), N_UNION_ALL)

  # The finding this qualification turned up: one of the thirteen (S39113) has
  # a death record but enrollyn == "N", so the standard mapping's enrolled
  # population — every gsm metric's denominator — does not contain them.
  expect_identical(length(l$UnionEnrolled), N_UNION_ENROLLED)
  expect_identical(setdiff(l$Union, l$Enrolled), "S39113")
})

test_that("route A: the saf0004 workflow over the standard mapping agrees (#56)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")

  lWorkflows <- gsm.core::MakeWorkflowList(
    strNames = c("SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death"),
    strPackage = "gsm.mapping"
  )
  lMapped <- suppressWarnings(suppressMessages({
    lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
    gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(gsm.core::lSource, lSpec))
  }))

  # gsm.mapping's own union, before any metric touches it: thirteen, the figure
  # the D0023 design published.
  dfDeath <- lMapped$Mapped_Death
  expect_identical(
    length(unique(dfDeath$subjid[!is.na(dfDeath$death) & dfDeath$death])),
    N_UNION_ALL
  )
  expect_identical(nrow(lMapped$Mapped_SUBJ), N_ENROLLED)

  lResult <- suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
    yaml::read_yaml(system.file(
      "workflow", "2_metrics", "saf0004.yaml",
      package = "gsm.safety"
    )),
    lData = lMapped
  )))
  dfSummary <- lResult$Analysis_Summary

  expect_identical(nrow(dfSummary), 1L)
  expect_identical(dfSummary$GroupLevel, "Study")
  expect_identical(dfSummary$Numerator, as.numeric(N_UNION_ENROLLED))
  expect_identical(dfSummary$Denominator, as.numeric(N_ENROLLED))
  expect_true(is.na(dfSummary$Flag))

  # The two routes, on the same study, must land on the same number.
  expect_identical(dfSummary$Numerator, as.numeric(length(RouteB()$UnionEnrolled)))

  # And the number the function reports today is the one being replaced.
  expect_gt(dfSummary$Numerator, 1)
})
