# The x-axis toggle between Visit and Study day (#166; hub obot.roadmap#438).
#
# safety.viz v1.12.0 gives every chart that shows change over time one
# setting, `x_axis`: { options: [{ key, col, label_col }], default }. The
# widgets hand `lSettings` to the chart unchanged, so the R side is the
# documentation, the examples, the report workflows and these tests: the
# setting reaches each payload as given, no example or workflow passes the
# visit number as the study day, and the workflows read the baseline flag.

lXAxis <- function(strDefault) {
  list(
    options = list(
      list(key = "visit", col = "VISITNUM", label_col = "VISIT"),
      list(key = "day", col = "DY")
    ),
    default = strDefault
  )
}

# The four widgets whose data contract takes `x_axis`, with the data each reads.
lToggleWidgets <- function() {
  list(
    Widget_ParticipantProfile = list(module = "participant-profile", data = "adbds", workflow = "participant_profile", default = "visit"),
    Widget_HepExplorer = list(module = "hep-explorer", data = "adbds", workflow = "hep_explorer", default = "day"),
    Widget_OutlierExplorer = list(module = "outlier-explorer", data = "adbds", workflow = "safety_outlier_explorer", default = "visit"),
    Widget_QtExplorer = list(module = "qt-explorer", data = "adeg", workflow = "qt_explorer", default = "visit")
  )
}

ReadModuleWorkflow <- function(strWorkflow) {
  strPath <- system.file("workflow", "4_modules", paste0(strWorkflow, ".yaml"), package = "gsm.safety")
  expect_true(file.exists(strPath), label = strWorkflow)
  yaml::read_yaml(strPath)
}

test_that("each widget with the toggle declares x_axis in its data contract (#166)", {
  for (strWidget in names(lToggleWidgets())) {
    lWidget <- lToggleWidgets()[[strWidget]]
    lSchema <- jsonlite::fromJSON(
      system.file("schema", paste0(lWidget$module, ".json"), package = "gsm.safety"),
      simplifyVector = FALSE
    )
    expect_false(is.null(lSchema$properties$settings$properties$x_axis), label = strWidget)
  }
})

test_that("x_axis reaches each widget's payload unchanged (#166)", {
  for (strWidget in names(lToggleWidgets())) {
    lWidget <- lToggleWidgets()[[strWidget]]
    lSettings <- list(x_axis = lXAxis(lWidget$default))
    fnWidget <- getExportedValue("gsm.safety", strWidget)

    lResult <- fnWidget(ExampleData(lWidget$data), lSettings = lSettings)

    expect_identical(lResult$x$lSettings$x_axis, lSettings$x_axis, label = strWidget)
  }
})

test_that("x_axis survives serialisation to the browser as an array of options (#166)", {
  lWidget <- Widget_ParticipantProfile(
    ExampleData("adbds"),
    lSettings = list(x_axis = lXAxis("day"))
  )
  lJSON <- jsonlite::fromJSON(
    htmlwidgets:::toJSON(lWidget$x$lSettings),
    simplifyVector = FALSE
  )
  expect_length(lJSON$x_axis$options, 2)
  expect_identical(lJSON$x_axis$options[[1]]$key, "visit")
  expect_identical(lJSON$x_axis$options[[2]]$col, "DY")
  expect_identical(lJSON$x_axis$default, "day")
})

test_that("no report workflow passes the visit number as the study day (#166)", {
  chrWorkflows <- list.files(
    system.file("workflow", "4_modules", package = "gsm.safety"),
    pattern = "[.]yaml$", full.names = TRUE
  )
  expect_gt(length(chrWorkflows), 0)
  for (strPath in chrWorkflows) {
    lSettings <- yaml::read_yaml(strPath)$meta$lSettings
    if (!is.null(lSettings$studyday_col)) {
      expect_false(identical(lSettings$studyday_col, "VISITNUM"), label = basename(strPath))
    }
  }
})

test_that("each toggle widget's workflow passes x_axis on visit number and study day (#166)", {
  for (strWidget in names(lToggleWidgets())) {
    lWidget <- lToggleWidgets()[[strWidget]]
    lWorkflow <- ReadModuleWorkflow(lWidget$workflow)
    lXAxisSetting <- lWorkflow$meta$lSettings$x_axis

    expect_false(is.null(lXAxisSetting), label = lWidget$workflow)
    expect_identical(
      vapply(lXAxisSetting$options, `[[`, "", "key"),
      c("visit", "day"),
      label = lWidget$workflow
    )
    expect_identical(lXAxisSetting$options[[1]]$col, "VISITNUM")
    expect_identical(lXAxisSetting$options[[1]]$label_col, "VISIT")
    expect_identical(lXAxisSetting$options[[2]]$col, "DY")
    expect_identical(lXAxisSetting$default, lWidget$default, label = lWidget$workflow)

    # The spec lists every column the axis plots, typed as the chart reads it.
    lSpec <- lWorkflow$spec$dfResults
    expect_identical(lSpec$DY$type, "numeric", label = lWidget$workflow)
    expect_identical(lSpec$VISITNUM$type, "numeric", label = lWidget$workflow)
  }
})

test_that("the lab workflows read the baseline flag, and hep-waterfall reads the study day (#166)", {
  for (strWorkflow in c("participant_profile", "hep_explorer", "hep_waterfall")) {
    lWorkflow <- ReadModuleWorkflow(strWorkflow)
    expect_identical(lWorkflow$meta$lSettings$baseline_col, "ABLFL", label = strWorkflow)
    expect_identical(lWorkflow$spec$dfResults$ABLFL$type, "character", label = strWorkflow)
  }
  lWaterfall <- ReadModuleWorkflow("hep_waterfall")
  expect_identical(lWaterfall$spec$dfResults$DY$type, "numeric")
})

test_that("each toggle widget's help sets x_axis in an example, and no example passes VISITNUM as the study day (#166)", {
  strRDir <- testthat::test_path("..", "..", "R")
  skip_if_not(dir.exists(strRDir), "R sources not available in this check context")
  for (strWidget in c(names(lToggleWidgets()), "Widget_HepWaterfall")) {
    chrLines <- readLines(file.path(strRDir, paste0(strWidget, ".R")), warn = FALSE)
    chrRoxygen <- grep("^#'", chrLines, value = TRUE)
    expect_false(any(grepl("studyday_col.*VISITNUM", chrRoxygen)), label = strWidget)
    if (strWidget %in% names(lToggleWidgets())) {
      nExamples <- grep("^#' @examples", chrRoxygen)
      expect_length(nExamples, 1)
      chrExamples <- chrRoxygen[seq(nExamples, length(chrRoxygen))]
      expect_true(any(grepl("x_axis = list(", chrExamples, fixed = TRUE)), label = paste(strWidget, "example"))
      nParam <- grep("^#' @param lSettings", chrRoxygen)
      expect_true(any(grepl("`x_axis`", chrRoxygen[seq(nParam, nParam + 12)], fixed = TRUE)), label = paste(strWidget, "lSettings doc"))
    }
  }
})

test_that("in the participant profile report's Study day view, 01-701-1028's day-21 event sits between the Week 2 and Week 4 labs (#166)", {
  lWorkflow <- ReadModuleWorkflow("participant_profile")
  lXAxisSetting <- lWorkflow$meta$lSettings$x_axis
  strDayCol <- lXAxisSetting$options[[which(vapply(lXAxisSetting$options, `[[`, "", "key") == "day")]]$col

  dfResults <- ExampleData("adbds")
  dfAE <- ExampleData("adae")
  dfLabs <- dfResults[dfResults$USUBJID == "01-701-1028", ]
  nEvent <- dfAE$ASTDY[dfAE$USUBJID == "01-701-1028" & dfAE$ASTDY == 21]
  expect_length(nEvent, 1)

  nWeek2 <- unique(dfLabs[[strDayCol]][dfLabs$VISIT == "Week 2"])
  nWeek4 <- unique(dfLabs[[strDayCol]][dfLabs$VISIT == "Week 4"])
  expect_length(nWeek2, 1)
  expect_length(nWeek4, 1)
  expect_lt(nWeek2, nEvent)
  expect_gt(nWeek4, nEvent)

  # On the visit number, as the report plotted it before, the event fell
  # after the Week 20 lab: this is the misplacement the change removes.
  expect_gt(nEvent, max(dfLabs$VISITNUM[dfLabs$VISIT == "Week 20"]))

  # And the report itself still renders from the example data.
  strOutputDir <- tempfile("participant_profile_x_axis")
  dir.create(strOutputDir, recursive = TRUE)
  strWd <- setwd(strOutputDir)
  on.exit(setwd(strWd), add = TRUE)
  strReportPath <- gsm.core::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(
      dfResults = dfResults,
      dfAE = dfAE[!is.na(dfAE$AEDECOD) & nzchar(dfAE$AEDECOD), ],
      chrParticipants = "01-701-1028"
    )
  )
  strHTML <- paste(readLines(strReportPath, warn = FALSE), collapse = "\n")
  expect_match(strHTML, '"x_axis":{"options":[{"key":"visit","col":"VISITNUM","label_col":"VISIT"},{"key":"day","col":"DY"}]', fixed = TRUE)
})
