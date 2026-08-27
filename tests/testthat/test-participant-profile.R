# The thirteenth widget (#71): the standalone participant profile.
#
# The design question hub#165 held this behind — standalone widget, compound
# chart-plus-rail widget, or profile-enabled variants of the lab widgets — is
# settled by the vendored bundle. `profileRail` is not exported on the
# `SafetyViz` global, so the compound mount cannot be reached from R at all;
# the profile-enabled lab widgets already ship (hep-explorer, histogram and
# outlier-explorer mount the rail from `settings.profile`); the standalone
# surface was the gap. It renders chrome and waits for a `participantsSelected`
# event that nothing in a static R report dispatches, so the cohort is a widget
# argument, delivered through the module's public `setSelected()`.

chrCohort <- function() {
  c("01-701-1015", "01-701-1023", "01-701-1028")
}

dfProfileAE <- function() {
  dfAE <- ExampleData("adae")
  dfAE[nzchar(dfAE$AEDECOD), ]
}

lProfileSettings <- function() {
  list(
    studyday_col = "VISITNUM",
    measure_values = list(
      ALT = "Alanine Aminotransferase",
      AST = "Aspartate Aminotransferase",
      TB = "Bilirubin",
      ALP = "Alkaline Phosphatase"
    ),
    details = list(
      list(value_col = "ARM", label = "Treatment Group"),
      list(value_col = "SEX", label = "Sex"),
      list(value_col = "RACE", label = "Race")
    )
  )
}

test_that("Widget_ParticipantProfile carries the labs, the cohort and the events (#71)", {
  dfResults <- ExampleData("adbds")
  dfAE <- dfProfileAE()
  lSettings <- lProfileSettings()

  lWidget <- Widget_ParticipantProfile(
    dfResults,
    chrParticipants = chrCohort(),
    dfAE = dfAE,
    lSettings = lSettings
  )

  expect_s3_class(lWidget, c("Widget_ParticipantProfile", "htmlwidget"))
  expect_identical(lWidget$x$dfResults, dfResults)
  expect_identical(lWidget$x$chrParticipants, chrCohort())
  expect_identical(lWidget$x$dfAE, dfAE)
  expect_identical(lWidget$x$lSettings, lSettings)
  expect_false(lWidget$x$bDebug)
})

test_that("Widget_ParticipantProfile without a cohort carries an empty selection (#71)", {
  lWidget <- Widget_ParticipantProfile(ExampleData("adbds"))

  expect_identical(lWidget$x$chrParticipants, character(0))
  expect_null(lWidget$x$dfAE)
})

test_that("Widget_ParticipantProfile passes width, height, and elementId through (#71)", {
  lWidget <- Widget_ParticipantProfile(
    ExampleData("adbds"),
    chrParticipants = chrCohort(),
    width = "100%",
    height = "600px",
    elementId = "participant-profile-widget",
    bDebug = TRUE
  )

  expect_identical(lWidget$width, "100%")
  expect_identical(lWidget$height, "600px")
  expect_identical(lWidget$elementId, "participant-profile-widget")
  expect_true(lWidget$x$bDebug)
})

test_that("Widget_ParticipantProfile rejects invalid inputs via its contract (#71)", {
  dfResults <- ExampleData("adbds")

  expect_error(Widget_ParticipantProfile("not a data.frame"))
  expect_error(
    Widget_ParticipantProfile(dfResults, chrParticipants = 1015),
    "chrParticipants"
  )
  expect_error(
    Widget_ParticipantProfile(dfResults, lSettings = list(value_col = "NOT_A_COLUMN")),
    "NOT_A_COLUMN.*value_col"
  )

  # The adverse-event frame rides in settings.ae.data rather than as a dataset
  # of its own, so BuildWidgetPayload never sees it. An unmapped id or onset
  # column would draw an empty timeline, which is indistinguishable from a
  # participant with no events — so it is an error here instead.
  expect_error(Widget_ParticipantProfile(dfResults, dfAE = "not a data.frame"), "dfAE")
  expect_error(
    Widget_ParticipantProfile(
      dfResults,
      dfAE = dfProfileAE(),
      lSettings = list(ae = list(stdy_col = "NOT_A_COLUMN"))
    ),
    "NOT_A_COLUMN.*ae[$]stdy_col"
  )
})

test_that("Widget_ParticipantProfile renders standalone HTML naming its cohort (#71)", {
  lWidget <- Widget_ParticipantProfile(
    ExampleData("adbds"),
    chrParticipants = chrCohort(),
    dfAE = dfProfileAE(),
    lSettings = lProfileSettings()
  )
  strReportPath <- file.path(tempfile("Widget_ParticipantProfile"), "profile.html")
  dir.create(dirname(strReportPath), recursive = TRUE)
  htmlwidgets::saveWidget(lWidget, file = strReportPath, selfcontained = TRUE)

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "HTMLWidgets.widget", fixed = TRUE)
  expect_match(strHTML, "SafetyViz.participantProfile(", fixed = TRUE)
  # Without this call the profile renders its chrome and waits forever.
  expect_match(strHTML, "instance.setSelected(ids)", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
  # A value only the adverse-event frame carries.
  expect_match(strHTML, "AEBODSYS", fixed = TRUE)
})

test_that("participant_profile workflow renders an HTML report from ExampleData (#71)", {
  strWorkflowPath <- system.file(
    "workflow", "4_modules", "participant_profile.yaml",
    package = "gsm.safety"
  )
  expect_true(file.exists(strWorkflowPath))
  lWorkflow <- yaml::read_yaml(strWorkflowPath)

  strOutputDir <- tempfile("participant_profile")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)

  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(
      dfResults = ExampleData("adbds"),
      dfAE = dfProfileAE(),
      chrParticipants = chrCohort()
    )
  )

  expect_match(strReportPath, "participant_profile[.]html$")
  expect_true(file.exists(strReportPath))

  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, "var SafetyViz", fixed = TRUE)
  expect_match(strHTML, "SafetyViz.participantProfile(", fixed = TRUE)
  expect_match(strHTML, "01-701-1015", fixed = TRUE)
})
