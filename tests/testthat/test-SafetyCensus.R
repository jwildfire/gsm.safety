# SafetyCensus() after the rebuild (#66, D0023). Step four of four.
#
# The function keeps its name, its arguments and the shape of what it returns.
# What changed is where its numbers come from: it runs the census metrics and
# reads what they published, and it counts nothing of its own.
#
# So the tests here are not "does the function do what the function does".
# Every fixture below is built so that the arithmetic the function used to do
# and the arithmetic the metrics do give *different* answers, and the test
# asserts the metric's answer. A function that kept its own counting could not
# pass them.

# ---- one study, four ways of being counted ----------------------------------
#
# S4 has a first-dose date and no time on treatment - dosed and stopped inside
# a day, the 18 participants the bundled study has in that state.
# GHOST is named by three domains and was never enrolled.
CENSUS_SUBJECTS <- data.frame(
  subjid = c("S1", "S2", "S3", "S4"),
  studyid = "AA-AA-000-0000",
  arm = c("A", "B", "A", ""),
  firstdosedate = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03", "2020-01-04")),
  timeonstudy = c(365L, 180L, 90L, 30L),
  timeontreatment = c(365L, 180L, 0L, 30L),
  stringsAsFactors = FALSE
)

CENSUS_DISPOSITION <- data.frame(
  subjid = c("S1", "S2", "S3", "GHOST"),
  compyn = c("Y", "N", "N", "Y"),
  compreas = c("", "Death", "Withdrew Consent", ""),
  stringsAsFactors = FALSE
)

# Two enrolled participants died and one who was never enrolled did. The
# study-completion domain's reason column names a different participant again,
# which is the whole point: the death count comes from the death domain now.
CENSUS_DEATH <- data.frame(
  subjid = c("S1", "S3", "GHOST"),
  death = TRUE,
  stringsAsFactors = FALSE
)

CENSUS_RANDOMIZATION <- data.frame(
  subjid = c("S1", "S2", "GHOST"), stringsAsFactors = FALSE
)

CENSUS_LABS <- data.frame(
  subjid = c("S1", "S1", "S2", "GHOST"),
  visnam = c("Baseline", "Week 4", "Baseline", "Baseline"),
  visnum = c(1, 2, 1, 1),
  stringsAsFactors = FALSE
)

CENSUS_ECG <- data.frame(subjid = c("S1", "S2"), stringsAsFactors = FALSE)
CENSUS_AE <- data.frame(subjid = c("S1", "S3", "S3"), stringsAsFactors = FALSE)

FullCensus <- function(...) {
  suppressWarnings(suppressMessages(SafetyCensus(
    dfSubjects = CENSUS_SUBJECTS,
    dfLabs = CENSUS_LABS,
    dfECG = CENSUS_ECG,
    dfAE = CENSUS_AE,
    dfDisposition = CENSUS_DISPOSITION,
    dfDeath = CENSUS_DEATH,
    dfRandomization = CENSUS_RANDOMIZATION,
    ...
  )))
}

CensusValue <- function(lOut, strLabel) {
  lOut$Census$Value[lOut$Census$Label == strLabel]
}

CensusDenominator <- function(lOut, strLabel) {
  lOut$Census$Denominator[lOut$Census$Label == strLabel]
}

DispositionCount <- function(lOut, strState) {
  lOut$Disposition$Participants[lOut$Disposition$State == strState]
}

# ---- the figures are the metrics' figures -----------------------------------

test_that("every figure SafetyCensus returns is one a census metric published (#66)", {
  lOut <- FullCensus()

  # Each of these four is a number the old arithmetic could not produce on this
  # fixture, and the value the metric publishes.
  #   deaths            was 1  - the discontinuation reason named S2 alone
  #   dosed             was 3  - inferred from time on treatment, dropping S4
  #   disposition       was 4  - counted GHOST, who was never enrolled
  #   randomised        was 3  - read the arm column rather than a domain
  expect_identical(CensusValue(lOut, "Deaths"), 2)
  expect_identical(CensusValue(lOut, "Received study drug"), 4)
  expect_identical(CensusValue(lOut, "Participants with a disposition record"), 3)
  expect_identical(CensusValue(lOut, "Randomised to an arm"), 2)

  # And the three that were already right stay right.
  expect_identical(CensusValue(lOut, "Enrolled participants"), 4)
  expect_identical(CensusValue(lOut, "Participants with a lab result"), 2)
  expect_identical(CensusValue(lOut, "Participants with a reported AE"), 2)
  expect_identical(CensusValue(lOut, "Participants with an ECG"), 2)
})

test_that("a change in what a metric publishes moves the figure by exactly that much (#66)", {
  # The law a reading function obeys and a counting one does not: the figure is
  # a function of the domain the metric reads, and of nothing else. The
  # study-completion domain is held constant throughout, so a function still
  # counting deaths from a discontinuation reason would return 1 every time.
  for (nDeaths in 0:3) {
    chrDied <- c("S1", "S2", "S3")[seq_len(nDeaths)]
    dfDeath <- data.frame(
      subjid = chrDied,
      death = rep(TRUE, length(chrDied)),
      stringsAsFactors = FALSE
    )
    lOut <- suppressWarnings(suppressMessages(SafetyCensus(
      dfSubjects = CENSUS_SUBJECTS,
      dfDisposition = CENSUS_DISPOSITION,
      dfDeath = dfDeath
    )))
    # An empty death domain has measured nothing, so it publishes nothing.
    nExpected <- if (nDeaths == 0) NA_real_ else as.numeric(nDeaths)
    expect_identical(CensusValue(lOut, "Deaths"), nExpected, info = nDeaths)
  }
})

test_that("a populated domain naming nobody is a zero, and an absent one is not (#66)", {
  # The distinction the whole rebuild is built on, carried out to the payload.
  lZero <- suppressWarnings(suppressMessages(SafetyCensus(
    dfSubjects = CENSUS_SUBJECTS,
    dfDeath = data.frame(
      subjid = c("S1", "S2"), death = FALSE, stringsAsFactors = FALSE
    )
  )))
  expect_identical(CensusValue(lZero, "Deaths"), 0)

  lAbsent <- suppressWarnings(suppressMessages(
    SafetyCensus(dfSubjects = CENSUS_SUBJECTS)
  ))
  expect_true(is.na(CensusValue(lAbsent, "Deaths")))
  expect_true(is.na(CensusValue(lAbsent, "Participants with a lab result")))
  expect_true(is.na(CensusValue(lAbsent, "Participants with an ECG")))
})

test_that("SafetyCensus says which domain it was not given (#66)", {
  # A figure that vanished without a word is the failure this package keeps
  # catching. An absent figure names the domain that would have produced it.
  expect_warning(
    SafetyCensus(dfSubjects = CENSUS_SUBJECTS),
    "Mapped_Death"
  )
})

# ---- what the safety overview reads by name ---------------------------------

test_that("the four labels the application looks up by name are unchanged (#66)", {
  # C5, approved: the demo application picks these out of the payload by exact
  # string and drops a tile silently if one is reworded. They are a contract.
  lOut <- FullCensus()
  for (strLabel in c(
    "Enrolled participants", "Received study drug",
    "Person-years on treatment", "Deaths"
  )) {
    expect_identical(
      sum(lOut$Census$Label == strLabel), 1L,
      info = strLabel
    )
  }
})

test_that("the payload keeps the shape the application already fetches (#66)", {
  lOut <- FullCensus()

  expect_identical(names(lOut), c("Census", "Coverage", "Disposition"))
  expect_identical(
    names(lOut$Census), c("Label", "Value", "Denominator", "Group")
  )
  expect_identical(
    names(lOut$Coverage),
    c("Domain", "Visit", "VisitNum", "Participants", "Expected")
  )
  expect_identical(names(lOut$Disposition), c("State", "Participants"))
  # The three groups the application filters its tile rows by.
  expect_identical(
    unique(lOut$Census$Group), c("Census", "Exposure", "Follow-up")
  )
})

test_that("a figure with no percentage to state carries no denominator (#66)", {
  # Every metric publishes a denominator, and the report shows it in a labelled
  # column. This payload has no such column: the application turns any
  # denominator into a percentage, so "73.2 person-years of 762 (10%)" is what
  # carrying it through would produce.
  lOut <- FullCensus()

  expect_true(is.na(CensusDenominator(lOut, "Enrolled participants")))
  expect_true(is.na(CensusDenominator(lOut, "Person-years on study")))
  expect_true(is.na(CensusDenominator(lOut, "Person-years on treatment")))
  expect_identical(CensusDenominator(lOut, "Deaths"), 4)
  expect_identical(CensusDenominator(lOut, "Received study drug"), 4)
})

test_that("person-time is the metrics' days, divided once and in the report (#66)", {
  lOut <- FullCensus()

  expect_equal(CensusValue(lOut, "Person-years on study"), round(665 / 365.25, 1))
  expect_equal(
    CensusValue(lOut, "Person-years on treatment"), round(575 / 365.25, 1)
  )
})

# ---- disposition -------------------------------------------------------------

test_that("the disposition table is the disposition metrics, and nothing else (#66)", {
  lOut <- FullCensus()

  expect_identical(DispositionCount(lOut, "Completed"), 1)
  expect_identical(DispositionCount(lOut, "Discontinued"), 2)
  expect_identical(DispositionCount(lOut, "Died"), 2)
  # Largest first, the order the application renders.
  expect_identical(
    lOut$Disposition$Participants,
    sort(lOut$Disposition$Participants, decreasing = TRUE)
  )
  # No state is invented. "Ongoing" was a participant whose completion flag was
  # blank, and "Not in the disposition domain" was a subtraction; no metric
  # publishes either, so neither is here (#66).
  expect_false(any(c("Ongoing", "Not in the disposition domain") %in%
    lOut$Disposition$State))
  expect_false(any(grepl("Discontinued - ", lOut$Disposition$State, fixed = TRUE)))
})

test_that("a study with no disposition domain has no disposition table (#66)", {
  lOut <- suppressWarnings(suppressMessages(
    SafetyCensus(dfSubjects = CENSUS_SUBJECTS)
  ))
  expect_identical(nrow(lOut$Disposition), 0L)
})

# ---- coverage ----------------------------------------------------------------

test_that("visit-level coverage leaves the payload until its metric lands (#66)", {
  # Data completeness is the thirteenth census figure and is not in this
  # release (#58): gsm.mapping's lab domain carries no visit column under the
  # standard mapping. The function used to count it from the raw domain, which
  # is the second counting lane this rebuild removes, so the table is empty
  # rather than computed here.
  lOut <- FullCensus()
  expect_identical(nrow(lOut$Coverage), 0L)
})

# ---- compatibility -----------------------------------------------------------

test_that("SafetyCensus keeps every argument it had, in the order it had them (#66)", {
  # A positional call keeps its meaning: the released arguments come first and
  # in the released order, and the new domains are appended after them.
  chrReleased <- c(
    "dfSubjects", "dfLabs", "dfECG", "dfAE", "dfDisposition", "strIDCol",
    "strArmCol", "strTimeOnStudyCol", "strTimeOnTreatmentCol",
    "strLabVisitCol", "strLabVisitNumCol", "strECGVisitCol",
    "strECGVisitNumCol", "strCompleteCol", "strReasonCol", "chrDeathValues"
  )
  chrFormals <- names(formals(SafetyCensus))
  expect_identical(chrFormals[seq_along(chrReleased)], chrReleased)
  expect_true(all(
    c("dfDeath", "dfRandomization", "strGroupCol") %in% chrFormals
  ))
})

test_that("the deprecated column arguments warn and are ignored (#66)", {
  # C5: deprecated and ignored, not removed. Passing one warns, names it, and
  # changes no figure.
  expect_warning(
    expect_warning(
      lOut <- suppressMessages(SafetyCensus(
        dfSubjects = CENSUS_SUBJECTS,
        dfDisposition = CENSUS_DISPOSITION,
        dfDeath = CENSUS_DEATH,
        strCompleteCol = "not_a_column",
        chrDeathValues = "NEVER MATCHES"
      )),
      "Deprecated and ignored"
    ),
    "No domain was supplied"
  )
  # Both arguments named the old arithmetic's inputs. The figures are unmoved.
  expect_identical(CensusValue(lOut, "Deaths"), 2)
  expect_identical(DispositionCount(lOut, "Completed"), 1)
})

test_that("a caller keying on another column name is still counted (#66)", {
  dfSubjects <- CENSUS_SUBJECTS
  names(dfSubjects)[names(dfSubjects) == "subjid"] <- "usubjid"
  names(dfSubjects)[names(dfSubjects) == "studyid"] <- "study"
  dfDeath <- CENSUS_DEATH
  names(dfDeath)[names(dfDeath) == "subjid"] <- "usubjid"

  lOut <- suppressWarnings(suppressMessages(SafetyCensus(
    dfSubjects = dfSubjects, dfDeath = dfDeath,
    strIDCol = "usubjid", strGroupCol = "study"
  )))
  expect_identical(CensusValue(lOut, "Enrolled participants"), 4)
  expect_identical(CensusValue(lOut, "Deaths"), 2)
})

test_that("a subject domain with no study identifier still counts, and says so (#66)", {
  # The study identifier never reaches this payload - it groups the metric and
  # is dropped - so requiring it would break a caller for a value the output
  # does not show.
  dfSubjects <- CENSUS_SUBJECTS[, setdiff(names(CENSUS_SUBJECTS), "studyid")]
  expect_warning(
    expect_warning(
      lOut <- suppressMessages(SafetyCensus(dfSubjects = dfSubjects)),
      "studyid"
    ),
    "No domain was supplied"
  )
  expect_identical(CensusValue(lOut, "Enrolled participants"), 4)
})

test_that("SafetyCensus rejects a subject domain it cannot key on (#45, #66)", {
  expect_error(SafetyCensus(CENSUS_SUBJECTS[, -1]), "subjid")
  expect_error(SafetyCensus("not a data frame"), "data.frame")
})

# ---- the function computes nothing -------------------------------------------

test_that("no arithmetic survives in SafetyCensus or its helpers (#66)", {
  # The deliverable this issue is measured by. A rebuild that left the counting
  # in place and put a workflow beside it would pass every test above by
  # accident of agreement; this one it cannot pass.
  #
  # What it proves: no operator and no aggregation that could produce a census
  # figure is named anywhere in these bodies. What it does not prove on its own
  # is that the numbers come from the metrics - the tests above do that, on
  # fixtures where a recount gives a different answer.
  chrForbidden <- c(
    "+", "-", "*", "/", "^", "%%", "%/%",
    "sum", "mean", "median", "round", "cumsum", "prod", "quantile",
    "tapply", "table", "aggregate", "rowSums", "colSums",
    "max", "min", "pmax", "pmin", "range", "cut", "findInterval",
    "unique", "duplicated", "intersect", "setdiff", "union"
  )
  chrBodies <- c(
    "SafetyCensus", ".WarnDeprecatedCensusArgs", ".CensusDomains",
    ".RenameColumn", ".CensusMetricWorkflows", ".CensusMetricResults",
    ".CensusRunMetric", ".CensusNoResults", ".CensusMetricDefinitions",
    ".CensusReportSettings", ".CensusFigureValue", ".LegacyCensus",
    ".LegacyCoverage", ".LegacyDisposition"
  )

  for (strName in chrBodies) {
    fun <- get(strName, envir = asNamespace("gsm.safety"))
    chrNames <- all.names(body(fun))
    expect_identical(
      intersect(chrNames, chrForbidden), character(0),
      info = strName
    )
  }
})

test_that("SafetyCensus runs the census metrics the report reads (#66)", {
  # One list of metric IDs, and it is the one the report's own settings name.
  # A metric added to the report and not here would be a figure the page shows
  # and the payload silently lacks.
  chrRun <- get(".CENSUS_METRIC_IDS", envir = asNamespace("gsm.safety"))
  lSettings <- yaml::read_yaml(system.file(
    "workflow", "4_modules", "safety_census.yaml",
    package = "gsm.safety"
  ))$meta$lSettings
  chrDeclared <- unlist(lapply(lSettings$Sections, function(l) unlist(l$Metrics)))

  expect_identical(sort(chrRun), sort(unique(chrDeclared)))
  expect_identical(anyDuplicated(chrRun), 0L)
})
