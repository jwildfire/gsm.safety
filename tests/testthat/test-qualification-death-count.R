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
# Two kinds of assertion live here, and the difference matters. The identities
# between the two routes hold on any version of the bundled study and are
# always checked. The exact counts are a snapshot of one study at one version,
# and gsm.safety tracks gsm.core's main branch, whose bundled study has already
# moved once: between gsm.core 1.2.0 and 1.3.1 the enrolled population went
# from 760 to 762 and the discontinuation-reason deaths from 1 to 4. So the
# snapshot is pinned to the version it was measured against, and a different
# version skips it with both numbers named rather than asserting a stale one.
#
# The recorded result and the reproducer are in
# design/death-count-qualification.md and tools/qualify-death-count.R.

# Measured 2026-08-21 against gsm.core 1.3.1 and gsm.mapping 1.1.6.
RECORDED <- list(
  gsm.core = "1.3.1",
  Enrolled = 762L,
  DeathDomain = 12L, # distinct participants with a death record
  Discontinuation = 4L, # distinct participants whose compreas is "Death"
  UnionAll = 16L, # the two sources combined, before the enrolment anchor
  UnionEnrolled = 13L, # the same union, restricted to enrolled participants
  NotEnrolled = c("S42425", "S97688", "S78705")
)

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
    UnionEnrolled = intersect(chrUnion, chrEnrolled),
    NotEnrolled = setdiff(chrUnion, chrEnrolled)
  )
}

SkipUnlessRecordedVersion <- function(l) {
  strInstalled <- as.character(utils::packageVersion("gsm.core"))
  if (identical(strInstalled, RECORDED$gsm.core)) {
    return(invisible(TRUE))
  }
  # Never a bare skip: the reason carries the live numbers, so a study that
  # moved cannot pass unseen.
  testthat::skip(paste0(
    "Bundled study snapshot not re-qualified. Recorded against gsm.core ",
    RECORDED$gsm.core, ": ", RECORDED$UnionEnrolled, " deaths of ",
    RECORDED$Enrolled, " enrolled. Installed gsm.core ", strInstalled,
    " reports ", length(l$UnionEnrolled), " of ", length(l$Enrolled),
    ". Re-run tools/qualify-death-count.R and update ",
    "design/death-count-qualification.md and this file."
  ))
}

test_that("route B: the two death sources read directly hold together (#56)", {
  l <- RouteB()

  # True of any study, and each one is a property the count depends on.
  expect_gt(length(l$Enrolled), 0L)
  expect_identical(
    length(l$Union),
    length(l$DeathDomain) + length(l$Discontinuation) -
      length(intersect(l$DeathDomain, l$Discontinuation))
  )
  expect_true(all(l$UnionEnrolled %in% l$Enrolled))
  expect_identical(
    sort(l$UnionEnrolled),
    sort(setdiff(l$Union, l$NotEnrolled))
  )
  expect_lte(length(l$UnionEnrolled), length(l$Union))
  # The figure SafetyCensus() reports today is one. Whatever the study, the
  # correction this metric exists to make has to be larger than that.
  expect_gt(length(l$UnionEnrolled), 1L)
})

test_that("route B: the recorded snapshot of the bundled study (#56)", {
  l <- RouteB()
  SkipUnlessRecordedVersion(l)

  expect_identical(length(l$Enrolled), RECORDED$Enrolled)
  expect_identical(length(l$DeathDomain), RECORDED$DeathDomain)
  expect_identical(length(l$Discontinuation), RECORDED$Discontinuation)
  # The two sources name entirely different participants on this study, which
  # is why the union is their sum rather than the larger of them.
  expect_identical(length(intersect(l$DeathDomain, l$Discontinuation)), 0L)
  expect_identical(length(l$Union), RECORDED$UnionAll)

  # The finding this qualification turned up: three of the sixteen have a death
  # record or a death discontinuation reason but enrollyn == "N", so the
  # standard mapping's enrolled population — every gsm metric's denominator —
  # does not contain them, and the published count is thirteen.
  expect_identical(length(l$UnionEnrolled), RECORDED$UnionEnrolled)
  expect_setequal(l$NotEnrolled, RECORDED$NotEnrolled)
})

RouteA <- function() {
  lWorkflows <- gsm.core::MakeWorkflowList(
    strNames = c("SUBJ", "STUDCOMP", "OverallResponse", "Randomization", "Death"),
    strPackage = "gsm.mapping"
  )
  lMapped <- suppressWarnings(suppressMessages({
    lSpec <- gsm.mapping::CombineSpecs(lWorkflows)
    gsm.core::RunWorkflows(lWorkflows, gsm.mapping::Ingest(gsm.core::lSource, lSpec))
  }))
  lResult <- suppressWarnings(suppressMessages(gsm.core::RunWorkflow(
    yaml::read_yaml(system.file(
      "workflow", "2_metrics", "saf0004.yaml",
      package = "gsm.safety"
    )),
    lData = lMapped
  )))
  list(Mapped = lMapped, Summary = lResult$Analysis_Summary)
}

test_that("route A: the saf0004 workflow agrees with the records (#56)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")

  lB <- RouteB()
  lA <- RouteA()
  dfSummary <- lA$Summary

  # gsm.mapping's own union, before any metric touches it, reproduced from the
  # raw records by a route that never calls gsm.mapping.
  dfDeath <- lA$Mapped$Mapped_Death
  expect_identical(
    length(unique(dfDeath$subjid[!is.na(dfDeath$death) & dfDeath$death])),
    length(lB$Union)
  )
  expect_identical(nrow(lA$Mapped$Mapped_SUBJ), length(lB$Enrolled))

  expect_identical(nrow(dfSummary), 1L)
  expect_identical(dfSummary$GroupLevel, "Study")
  expect_true(is.na(dfSummary$Flag))

  # The check itself: the two routes, on the same study, land on the same
  # number, and it is the union anchored to the enrolled population.
  expect_identical(dfSummary$Numerator, as.numeric(length(lB$UnionEnrolled)))
  expect_identical(dfSummary$Denominator, as.numeric(length(lB$Enrolled)))
  expect_lte(dfSummary$Numerator, dfSummary$Denominator)
  # And the number the function reports today is the one being replaced.
  expect_gt(dfSummary$Numerator, 1)
})

test_that("route A: the recorded snapshot of the published row (#56)", {
  skip_if_not_installed("gsm.mapping")
  skip_if_not_installed("yaml")
  SkipUnlessRecordedVersion(RouteB())

  dfSummary <- RouteA()$Summary

  expect_identical(dfSummary$Numerator, as.numeric(RECORDED$UnionEnrolled))
  expect_identical(dfSummary$Denominator, as.numeric(RECORDED$Enrolled))
})
