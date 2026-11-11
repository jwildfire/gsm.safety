# Fixtures. Two enrolled participants in one study; one of them has a death
# record. GHOST has a death record but was never enrolled.
SUBJ <- data.frame(
  subjid = c("S1", "S2"),
  studyid = "AA-AA-000-0000",
  stringsAsFactors = FALSE
)
DEATH <- data.frame(
  subjid = c("S1", "S2"),
  death = c(TRUE, NA),
  stringsAsFactors = FALSE
)

Count <- function(dfInput) sum(dfInput$Numerator)

test_that("Input_Deaths counts a participant once and anchors to the enrolled (#56)", {
  dfInput <- Input_Deaths(DEATH, SUBJ)

  expect_identical(nrow(dfInput), 2L)
  expect_true(all(c(
    "SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric"
  ) %in% names(dfInput)))
  expect_identical(unique(dfInput$GroupLevel), "Study")
  expect_identical(unique(dfInput$GroupID), "AA-AA-000-0000")
  expect_identical(Count(dfInput), 1)
  expect_identical(sum(dfInput$Denominator), 2)
})

test_that("duplicating a death row changes nothing (#56)", {
  # The standing rule from the D0023 design: every count metric reduces its
  # domain to one row per participant before counting.
  dfDup <- rbind(DEATH, DEATH[1, , drop = FALSE], DEATH[1, , drop = FALSE])

  expect_identical(Count(Input_Deaths(dfDup, SUBJ)), Count(Input_Deaths(DEATH, SUBJ)))
})

test_that("duplicating a subject row changes no denominator (#56)", {
  dfDup <- rbind(SUBJ, SUBJ[1, , drop = FALSE])
  dfInput <- Input_Deaths(DEATH, dfDup)

  expect_identical(nrow(dfInput), 2L)
  expect_identical(sum(dfInput$Denominator), 2)
})

test_that("a participant never enrolled is never counted (#56)", {
  # The other standing rule: an identifier that appears in a domain but not in
  # the enrolled population cannot push a numerator past its denominator.
  dfDeath <- rbind(DEATH, data.frame(
    subjid = "GHOST", death = TRUE, stringsAsFactors = FALSE
  ))
  dfInput <- Input_Deaths(dfDeath, SUBJ)

  expect_false("GHOST" %in% dfInput$SubjectID)
  expect_identical(Count(dfInput), 1)
  expect_lte(Count(dfInput), sum(dfInput$Denominator))
})

test_that("an absent death domain errors rather than reporting zero (#56)", {
  # State one of three. gsm.core::CheckSpec() only *warns* on a declared column
  # that is missing (it errors only on a missing data.frame), so the guarantee
  # that a missing column stops the metric has to live here.
  expect_error(Input_Deaths(NULL, SUBJ), "dfDeath")
  expect_error(Input_Deaths("not a data.frame", SUBJ), "dfDeath")
  expect_error(Input_Deaths(DEATH[, "subjid", drop = FALSE], SUBJ), "death")
  expect_error(Input_Deaths(DEATH[, "death", drop = FALSE], SUBJ), "subjid")
  expect_error(Input_Deaths(DEATH, NULL), "dfSubjects")
  expect_error(Input_Deaths(DEATH, SUBJ[, "subjid", drop = FALSE]), "studyid")
})

test_that("an empty death domain publishes no figure, not a zero (#56)", {
  # State two of three. A domain with no rows at all has measured nothing, so
  # it reports no figure; a zero here would be a green light nobody gave.
  expect_warning(dfInput <- Input_Deaths(DEATH[0, , drop = FALSE], SUBJ), "empty")

  expect_identical(nrow(dfInput), 0L)
  expect_true(all(c(
    "SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric"
  ) %in% names(dfInput)))
})

test_that("a populated death domain with no deaths is a measured zero (#56)", {
  # State three of three, and the one that is genuinely zero: the domain ran
  # and the answer is none.
  dfNone <- data.frame(subjid = c("S1", "S2"), death = NA, stringsAsFactors = FALSE)
  dfInput <- Input_Deaths(dfNone, SUBJ)

  expect_identical(nrow(dfInput), 2L)
  expect_identical(Count(dfInput), 0)
  expect_identical(sum(dfInput$Denominator), 2)
})

test_that("Input_Deaths reads the death flag however the study spells it (#56)", {
  for (vDeath in list(c(TRUE, FALSE), c(1, 0), c("TRUE", "FALSE"), c("Y", "N"))) {
    dfDeath <- data.frame(subjid = c("S1", "S2"), death = vDeath, stringsAsFactors = FALSE)
    expect_identical(Count(Input_Deaths(dfDeath, SUBJ)), 1, info = class(vDeath))
  }
})

test_that("the group level and column are settings, not a rewrite (#56)", {
  # D0023.4: study level ships first, but moving the metric to site level is a
  # change of two arguments rather than a different metric.
  dfSubjects <- data.frame(
    subjid = c("S1", "S2"), invid = c("0X1", "0X2"), stringsAsFactors = FALSE
  )
  dfInput <- Input_Deaths(
    DEATH, dfSubjects,
    strGroupCol = "invid", strGroupLevel = "Site"
  )

  expect_identical(unique(dfInput$GroupLevel), "Site")
  expect_setequal(dfInput$GroupID, c("0X1", "0X2"))
})

# The study-completion domain (#168). gsm.mapping 1.2.0 matches the
# discontinuation reason against "DEATH" exactly, and gsm.core 1.3.2's study
# writes "Death", so Mapped_Death stopped carrying those participants. The
# count reads the reason itself, in any case.
COMP <- data.frame(
  subjid = c("S1", "S2"),
  compreas = c(NA, "Death"),
  stringsAsFactors = FALSE
)
NODEATH <- data.frame(subjid = c("S1", "S2"), death = c(NA, NA), stringsAsFactors = FALSE)

test_that("a discontinuation reason of death counts, in any case (#168)", {
  for (strReason in c("Death", "DEATH", "death", " Death ")) {
    dfComp <- COMP
    dfComp$compreas[2] <- strReason
    expect_identical(
      Count(Input_Deaths(NODEATH, SUBJ, dfStudyCompletion = dfComp)),
      1,
      label = strReason
    )
  }
})

test_that("the two death sources are a union, each participant counted once (#168)", {
  dfComp <- data.frame(subjid = c("S1", "S2"), compreas = c("DEATH", "Death"), stringsAsFactors = FALSE)
  # S1 is in both sources, S2 only in the completion domain.
  expect_identical(Count(Input_Deaths(DEATH, SUBJ, dfStudyCompletion = dfComp)), 2)
  # Without the completion domain the count is the death domain alone.
  expect_identical(Count(Input_Deaths(DEATH, SUBJ)), 1)
})

test_that("other discontinuation reasons, and reasons that only contain the word, do not count (#168)", {
  dfComp <- data.frame(
    subjid = c("S1", "S2"),
    compreas = c("Adverse Event", "Death of a relative"),
    stringsAsFactors = FALSE
  )
  expect_identical(Count(Input_Deaths(NODEATH, SUBJ, dfStudyCompletion = dfComp)), 0)
})

test_that("a death discontinuation still counts only the enrolled (#168)", {
  dfComp <- data.frame(subjid = c("S2", "GHOST"), compreas = c("Death", "Death"), stringsAsFactors = FALSE)
  dfInput <- Input_Deaths(NODEATH, SUBJ, dfStudyCompletion = dfComp)
  expect_identical(Count(dfInput), 1)
  expect_identical(sum(dfInput$Denominator), 2)
})

test_that("a study-completion domain without its reason column errors (#168)", {
  dfComp <- data.frame(subjid = "S2", reason = "Death", stringsAsFactors = FALSE)
  expect_error(
    Input_Deaths(NODEATH, SUBJ, dfStudyCompletion = dfComp),
    "compreas"
  )
})

test_that("an unresolved completion-domain name is read as no completion domain (#168)", {
  # A workflow step names its inputs; when the named domain was not supplied
  # the engine passes the name itself as a string. That is absence, not data.
  expect_identical(
    Count(Input_Deaths(DEATH, SUBJ, dfStudyCompletion = "Mapped_STUDCOMP")),
    Count(Input_Deaths(DEATH, SUBJ))
  )
})
