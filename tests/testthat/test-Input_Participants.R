# Fixtures. Four enrolled participants in one study. GHOST appears in the
# domain but was never enrolled.
SUBJ <- data.frame(
  subjid = c("S1", "S2", "S3", "S4"),
  studyid = "AA-AA-000-0000",
  stringsAsFactors = FALSE
)
DOMAIN <- data.frame(
  subjid = c("S1", "S2", "S3"),
  compyn = c("Y", "N", NA),
  stringsAsFactors = FALSE
)

Count <- function(dfInput) sum(dfInput$Numerator)

test_that("Input_Participants counts each participant once, anchored to the enrolled (#58)", {
  dfInput <- Input_Participants(DOMAIN, SUBJ)

  expect_identical(nrow(dfInput), 4L)
  expect_true(all(c(
    "SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric"
  ) %in% names(dfInput)))
  expect_identical(unique(dfInput$GroupLevel), "Study")
  expect_identical(unique(dfInput$GroupID), "AA-AA-000-0000")
  expect_identical(Count(dfInput), 3)
  expect_identical(sum(dfInput$Denominator), 4)
})

test_that("duplicating a domain row changes nothing (#58)", {
  # The standing rule from the D0023 design: every count metric reduces its
  # domain to one row per participant before counting.
  dfDup <- rbind(DOMAIN, DOMAIN[1, , drop = FALSE], DOMAIN[1, , drop = FALSE])

  expect_identical(Count(Input_Participants(dfDup, SUBJ)), Count(Input_Participants(DOMAIN, SUBJ)))
})

test_that("duplicating a subject row changes no denominator (#58)", {
  dfDup <- rbind(SUBJ, SUBJ[1, , drop = FALSE])
  dfInput <- Input_Participants(DOMAIN, dfDup)

  expect_identical(nrow(dfInput), 4L)
  expect_identical(sum(dfInput$Denominator), 4)
})

test_that("a participant never enrolled is never counted (#58)", {
  dfDomain <- rbind(DOMAIN, data.frame(
    subjid = "GHOST", compyn = "Y", stringsAsFactors = FALSE
  ))
  dfInput <- Input_Participants(dfDomain, SUBJ)

  expect_false("GHOST" %in% dfInput$SubjectID)
  expect_identical(Count(dfInput), 3)
  expect_lte(Count(dfInput), sum(dfInput$Denominator))
})

test_that("a filter value counts only the participants whose column matches (#58)", {
  expect_identical(Count(Input_Participants(DOMAIN, SUBJ, strFilterCol = "compyn", strFilterValues = "Y")), 1)
  expect_identical(Count(Input_Participants(DOMAIN, SUBJ, strFilterCol = "compyn", strFilterValues = "N")), 1)
  # Comma-separated, the ecosystem's convention for a multi-valued meta scalar.
  expect_identical(Count(Input_Participants(DOMAIN, SUBJ, strFilterCol = "compyn", strFilterValues = "Y, N")), 2)
})

test_that("the filter match ignores case and surrounding space (#58)", {
  dfDomain <- data.frame(
    subjid = c("S1", "S2"), compyn = c(" y ", "no"), stringsAsFactors = FALSE
  )
  expect_identical(Count(Input_Participants(dfDomain, SUBJ, strFilterCol = "compyn", strFilterValues = "Y")), 1)
})

test_that("a filter column with no values counts a recorded value of any kind (#58)", {
  # How 'dosed' is counted: a first-dose date that is present, rather than a
  # treatment duration inferred to be greater than zero.
  dfDomain <- data.frame(
    subjid = c("S1", "S2", "S3", "S4"),
    firstdosedate = as.Date(c("2012-01-01", NA, "2012-02-01", "2012-03-01")),
    stringsAsFactors = FALSE
  )
  expect_identical(Count(Input_Participants(dfDomain, SUBJ, strFilterCol = "firstdosedate")), 3)

  # A blank string is not a recorded value either.
  dfBlank <- data.frame(
    subjid = c("S1", "S2"), arm = c("A", "  "), stringsAsFactors = FALSE
  )
  expect_identical(Count(Input_Participants(dfBlank, SUBJ, strFilterCol = "arm")), 1)
})

test_that("a zero is a measurement: a populated domain matching nobody reports 0 (#58)", {
  dfInput <- Input_Participants(DOMAIN, SUBJ, strFilterCol = "compyn", strFilterValues = "MAYBE")

  expect_identical(nrow(dfInput), 4L)
  expect_identical(Count(dfInput), 0)
  expect_identical(sum(dfInput$Denominator), 4)
})

test_that("an absent domain or column errors rather than reporting zero (#58)", {
  # gsm.core::CheckSpec() only *warns* on a declared column that is missing (it
  # errors only on a missing data.frame), so the guarantee has to live here.
  expect_error(Input_Participants(NULL, SUBJ), "not a data.frame")
  expect_error(Input_Participants("not a data.frame", SUBJ), "not a data.frame")
  expect_error(Input_Participants(DOMAIN[, "compyn", drop = FALSE], SUBJ), "subjid")
  expect_error(Input_Participants(DOMAIN, SUBJ, strFilterCol = "arm"), "arm")
  expect_error(Input_Participants(DOMAIN, NULL), "dfSubjects")
  expect_error(Input_Participants(DOMAIN, SUBJ[, "subjid", drop = FALSE]), "studyid")
})

test_that("the domain name reaches the error message a reader has to act on (#58)", {
  expect_error(
    Input_Participants(DOMAIN, SUBJ, strFilterCol = "arm", strDomainName = "Mapped_STUDCOMP"),
    "Mapped_STUDCOMP"
  )
})

test_that("an empty domain publishes no figure, not a zero (#58)", {
  expect_warning(dfInput <- Input_Participants(DOMAIN[0, , drop = FALSE], SUBJ), "empty")

  expect_identical(nrow(dfInput), 0L)
  expect_true(all(c(
    "SubjectID", "GroupID", "GroupLevel", "Numerator", "Denominator", "Metric"
  ) %in% names(dfInput)))
})

test_that("an empty enrolled population publishes no figure either (#58)", {
  # No denominator is not a denominator of zero, and it is not a count of zero.
  expect_warning(dfInput <- Input_Participants(DOMAIN, SUBJ[0, , drop = FALSE]), "enrolled")

  expect_identical(nrow(dfInput), 0L)
})

test_that("the group level and column are settings, not a rewrite (#58)", {
  # D0023.4: study level ships first, but moving a metric to site level is a
  # change of two arguments rather than a different metric.
  dfSubjects <- data.frame(
    subjid = c("S1", "S2", "S3", "S4"),
    invid = c("0X1", "0X1", "0X2", "0X2"),
    stringsAsFactors = FALSE
  )
  dfInput <- Input_Participants(
    DOMAIN, dfSubjects,
    strGroupCol = "invid", strGroupLevel = "Site"
  )

  expect_identical(unique(dfInput$GroupLevel), "Site")
  expect_setequal(dfInput$GroupID, c("0X1", "0X2"))
})
