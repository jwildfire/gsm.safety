# Fixtures. Four enrolled participants with person-time in days, the unit the
# subject domain records and the unit the metric publishes.
SUBJ_DAYS <- data.frame(
  subjid = c("S1", "S2", "S3", "S4"),
  studyid = "AA-AA-000-0000",
  timeonstudy = c(10, 20, 30, 40),
  timeontreatment = c(5, 0, 15, 20),
  stringsAsFactors = FALSE
)

Total <- function(dfInput) sum(dfInput$Numerator)

test_that("Input_ParticipantDays sums the days the subject domain records (#58)", {
  dfInput <- Input_ParticipantDays(SUBJ_DAYS, "timeonstudy")

  expect_identical(nrow(dfInput), 4L)
  expect_true(all(c(
    "SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric"
  ) %in% names(dfInput)))
  expect_identical(unique(dfInput$GroupLevel), "Study")
  expect_identical(Total(dfInput), 100)
  expect_identical(sum(dfInput$Denominator), 4)
})

test_that("days are published as days, never converted to years (#58)", {
  # D0023: participant-days are published as the number actually summed; the
  # report is where years are presented.
  expect_identical(Total(Input_ParticipantDays(SUBJ_DAYS, "timeontreatment")), 40)
})

test_that("duplicating a subject row changes neither the total nor the denominator (#58)", {
  dfDup <- rbind(SUBJ_DAYS, SUBJ_DAYS[1, , drop = FALSE], SUBJ_DAYS[3, , drop = FALSE])
  dfInput <- Input_ParticipantDays(dfDup, "timeonstudy")

  expect_identical(nrow(dfInput), 4L)
  expect_identical(Total(dfInput), 100)
  expect_identical(sum(dfInput$Denominator), 4)
})

test_that("a recorded zero counts as a participant with no time, not as no participant (#58)", {
  # S2 has zero days on treatment. Zero is a measurement: they are still in the
  # denominator, and the mean is over four participants rather than three.
  dfInput <- Input_ParticipantDays(SUBJ_DAYS, "timeontreatment")

  expect_identical(sum(dfInput$Denominator), 4)
  expect_identical(sum(dfInput$Numerator) / sum(dfInput$Denominator), 10)
})

test_that("a participant whose person-time is missing leaves both sides of the figure (#58)", {
  # Person-time that was never recorded is not zero days. Counting it as zero
  # would understate the total and inflate the denominator at the same time,
  # so the participant leaves the numerator and the denominator together and
  # the metric says how many did.
  dfMissing <- SUBJ_DAYS
  dfMissing$timeonstudy[2] <- NA
  expect_warning(dfInput <- Input_ParticipantDays(dfMissing, "timeonstudy"), "S2")

  expect_identical(Total(dfInput), 80)
  expect_identical(sum(dfInput$Denominator), 3)
  expect_identical(nrow(dfInput), 3L)
})

test_that("a negative person-time is not quietly summed (#58)", {
  dfBad <- SUBJ_DAYS
  dfBad$timeonstudy[3] <- -5
  expect_warning(dfInput <- Input_ParticipantDays(dfBad, "timeonstudy"), "negative")

  expect_identical(Total(dfInput), 70)
  expect_identical(sum(dfInput$Denominator), 3)
})

test_that("an absent domain or column errors rather than reporting zero days (#58)", {
  expect_error(Input_ParticipantDays(NULL, "timeonstudy"), "not a data.frame")
  expect_error(Input_ParticipantDays(SUBJ_DAYS, "timeontrt"), "timeontrt")
  expect_error(Input_ParticipantDays(SUBJ_DAYS[, c("subjid", "studyid")], "timeonstudy"), "timeonstudy")
  expect_error(Input_ParticipantDays(SUBJ_DAYS[, c("studyid", "timeonstudy")], "timeonstudy"), "subjid")
  expect_error(Input_ParticipantDays(SUBJ_DAYS[, c("subjid", "timeonstudy")], "timeonstudy"), "studyid")
  expect_error(
    Input_ParticipantDays(SUBJ_DAYS, "timeontrt", strDomainName = "Mapped_SUBJ"),
    "Mapped_SUBJ"
  )
})

test_that("a person-time column that is not a number errors (#58)", {
  dfText <- SUBJ_DAYS
  dfText$timeonstudy <- c("ten", "twenty", "thirty", "forty")

  expect_error(Input_ParticipantDays(dfText, "timeonstudy"), "numeric")
})

test_that("an empty subject domain publishes no figure, not zero days (#58)", {
  expect_warning(
    dfInput <- Input_ParticipantDays(SUBJ_DAYS[0, , drop = FALSE], "timeonstudy"),
    "enrolled"
  )

  expect_identical(nrow(dfInput), 0L)
})

test_that("a domain where nobody has a recorded time publishes no figure (#58)", {
  dfNone <- SUBJ_DAYS
  dfNone$timeonstudy <- NA_real_

  chrWarnings <- character(0)
  dfInput <- withCallingHandlers(
    Input_ParticipantDays(dfNone, "timeonstudy"),
    warning = function(w) {
      chrWarnings <<- c(chrWarnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  # Two warnings, both of them load-bearing: who left the figure, and that no
  # figure is published at all.
  expect_length(chrWarnings, 2L)
  expect_match(chrWarnings[[1]], "no recorded value")
  expect_match(chrWarnings[[2]], "no figure is published")
  expect_identical(nrow(dfInput), 0L)
})

test_that("the group level and column are settings, not a rewrite (#58)", {
  dfSubjects <- SUBJ_DAYS
  dfSubjects$invid <- c("0X1", "0X1", "0X2", "0X2")
  dfInput <- Input_ParticipantDays(
    dfSubjects, "timeonstudy",
    strGroupCol = "invid", strGroupLevel = "Site"
  )

  expect_identical(unique(dfInput$GroupLevel), "Site")
  expect_setequal(dfInput$GroupID, c("0X1", "0X2"))
})
