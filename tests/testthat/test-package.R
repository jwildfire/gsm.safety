test_that("package metadata is available (#31)", {
  expect_equal(utils::packageDescription("gsm.safety")$Package, "gsm.safety")
})

test_that("gsm.safety exports the thirteen safety.viz widgets plus data, report and metric helpers (#31, #41, #42, #45, #49, #56, #58, #61, #71)", {
  expect_setequal(
    getNamespaceExports("gsm.safety"),
    c(
      "Widget_Histogram",
      "Widget_ShiftPlot",
      "Widget_DeltaDelta",
      "Widget_ResultsOverTime",
      "Widget_OutlierExplorer",
      "Widget_AeTimelines",
      "Widget_HepExplorer",
      "Widget_AeExplorer",
      "Widget_QtExplorer",
      "Widget_HepWaterfall",
      "Widget_NepExplorer",
      "Widget_TimeToEvent",
      "Widget_ParticipantProfile",
      "ExampleData",
      "SaveWidgetReport",
      # The 2_metrics phase: one Input_* step per participant-level metric.
      "Input_HysLaw",
      "Input_QtProlongation",
      "Input_SafetyAE",
      # The census metrics: descriptive counts and the step that stands where
      # a flagging metric calls gsm.core::Flag().
      "Input_Deaths",
      "Input_Participants",
      "Input_ParticipantDays",
      "Flag_None",
      # The Safety overview's denominators.
      "SafetyCensus",
      # The census report: the steps of the safety_census workflow, which read
      # the figures the census metrics published and compute nothing.
      "Report_CensusFigures",
      "Report_CensusCoverage",
      "Report_CensusProvenance",
      "Report_SafetyCensus"
    )
  )
})

test_that("every renderer exported by the vendored safety.viz bundle has a widget binding (#41, #42, #49)", {
  # The bundle's public module collection is the contract: a renderer that
  # ships in safety.viz but has no Widget_* binding is unreachable from R.
  strVersion <- utils::packageDescription("gsm.safety")[["Config/safetyviz/version"]]
  strBundle <- system.file(
    "htmlwidgets", "lib", paste0("safety.viz-", strVersion), "safety.viz.js",
    package = "gsm.safety"
  )
  expect_true(nzchar(strBundle))

  chrModules <- c(
    "histogram", "shiftPlot", "deltaDelta", "resultsOverTime",
    "outlierExplorer", "aeTimelines", "hepExplorer", "aeExplorer", "qtExplorer",
    "hepWaterfall", "nepExplorer", "timeToEvent", "participantProfile"
  )
  # Deferred wraps: every entry MUST cite its filed requirement (the parity
  # rule's single-release clause) and mirror .github/parity-allowlist.yaml.
  # Empty since #71 wrapped the last two: every renderer the bundle exports is
  # reachable from R.
  chrDeferred <- character(0)
  chrBindings <- basename(list.files(
    system.file("htmlwidgets", package = "gsm.safety"),
    pattern = "^Widget_.*[.]js$"
  ))
  strBindingSource <- paste(
    vapply(
      file.path(system.file("htmlwidgets", package = "gsm.safety"), chrBindings),
      function(strPath) paste(readLines(strPath, warn = FALSE), collapse = "\n"),
      character(1)
    ),
    collapse = "\n"
  )

  for (strModule in chrModules) {
    expect_match(
      strBindingSource,
      paste0("SafetyViz.", strModule, "("),
      fixed = TRUE,
      info = strModule
    )
  }
  for (strModule in chrDeferred) {
    expect_no_match(
      strBindingSource,
      paste0("SafetyViz.", strModule, "("),
      fixed = TRUE,
      info = paste0(strModule, " is deferred — wrap it or drop it from chrDeferred")
    )
  }
  # Every deferral must cite a filed requirement, and the two lists must agree:
  # a module dropped from one file and left in the other is how a wrapped
  # renderer keeps reporting itself as deferred.
  strAllowlist <- testthat::test_path("..", "..", ".github", "parity-allowlist.yaml")
  if (file.exists(strAllowlist)) {
    lAllowlist <- yaml::read_yaml(strAllowlist)
    if (is.null(lAllowlist)) {
      lAllowlist <- list()
    }
    expect_setequal(
      vapply(lAllowlist, function(lEntry) lEntry$module, character(1)),
      chrDeferred
    )
    # "Widget follows later" is only a commitment if it names the requirement.
    for (lEntry in lAllowlist) {
      expect_match(
        lEntry$requirement,
        "^https://github[.]com/.+/issues/[0-9]+$",
        info = lEntry$module
      )
    }
  }
  expect_length(chrBindings, length(chrModules))
})

test_that("every widget binding feeds the module, not just constructs it (#71)", {
  # A binding that constructs the renderer and never hands it data raises no
  # console error, still emits a .html-widget element, still ships the bundle,
  # and still carries every data value in the payload — measured on a
  # deliberately broken copy. It is indistinguishable from a working widget by
  # every assertion above, and by every assertion in the widget test files.
  # What separates them is the feed call, so the feed call is what is asserted.
  chrBindings <- list.files(
    system.file("htmlwidgets", package = "gsm.safety"),
    pattern = "^Widget_.*[.]js$",
    full.names = TRUE
  )
  expect_gt(length(chrBindings), 0)

  for (strPath in chrBindings) {
    strSource <- paste(readLines(strPath, warn = FALSE), collapse = "\n")
    strWidget <- sub("[.]js$", "", basename(strPath))

    # The renderer is constructed...
    expect_match(strSource, "SafetyViz[.][a-zA-Z]+\\(", info = strWidget)

    # ...and fed. Every safety.viz module takes its data through init/setData;
    # participant-profile takes it as the factory's second argument instead.
    expect_match(
      strSource,
      "instance[.](init|setData)\\(|SafetyViz[.][a-zA-Z]+\\([[:space:]]*el,[[:space:]]*$|SafetyViz[.][a-zA-Z]+\\([[:space:]]*el,[[:space:]]*HTMLWidgets",
      info = paste0(strWidget, " constructs the module but never feeds it data")
    )

    # ...from the payload, not from a literal.
    expect_match(
      strSource,
      "HTMLWidgets.dataframeToD3(x.",
      fixed = TRUE,
      info = strWidget
    )
  }
})

test_that("every widget ships its htmlwidgets binding, dependency yaml, schema, and report workflow (#31, #38, #49)", {
  lWidgets <- list(
    Widget_Histogram = list(slug = "histogram", workflow = "safety_histogram"),
    Widget_ShiftPlot = list(slug = "shift-plot", workflow = "safety_shift_plot"),
    Widget_DeltaDelta = list(slug = "delta-delta", workflow = "safety_delta_delta"),
    Widget_ResultsOverTime = list(slug = "results-over-time", workflow = "safety_results_over_time"),
    Widget_OutlierExplorer = list(slug = "outlier-explorer", workflow = "safety_outlier_explorer"),
    Widget_AeTimelines = list(slug = "ae-timelines", workflow = "ae_timelines"),
    Widget_HepExplorer = list(slug = "hep-explorer", workflow = "hep_explorer"),
    Widget_AeExplorer = list(slug = "ae-explorer", workflow = "ae_explorer"),
    Widget_QtExplorer = list(slug = "qt-explorer", workflow = "qt_explorer"),
    Widget_HepWaterfall = list(slug = "hep-waterfall", workflow = "hep_waterfall"),
    Widget_NepExplorer = list(slug = "nep-explorer", workflow = "nep_explorer"),
    Widget_TimeToEvent = list(slug = "time-to-event", workflow = "time_to_event"),
    Widget_ParticipantProfile = list(
      slug = "participant-profile", workflow = "participant_profile"
    )
  )

  for (strWidget in names(lWidgets)) {
    lWidget <- lWidgets[[strWidget]]
    expect_true(
      nzchar(system.file(
        "htmlwidgets", paste0(strWidget, ".js"),
        package = "gsm.safety"
      )),
      info = strWidget
    )
    expect_true(
      nzchar(system.file(
        "htmlwidgets", paste0(strWidget, ".yaml"),
        package = "gsm.safety"
      )),
      info = strWidget
    )
    expect_true(
      nzchar(system.file(
        "schema", paste0(lWidget$slug, ".json"),
        package = "gsm.safety"
      )),
      info = strWidget
    )
    expect_true(
      nzchar(system.file(
        "workflow", "4_modules", paste0(lWidget$workflow, ".yaml"),
        package = "gsm.safety"
      )),
      info = strWidget
    )
  }

  strVersion <- utils::packageDescription("gsm.safety")[["Config/safetyviz/version"]]
  expect_true(
    nzchar(system.file(
      "htmlwidgets", "lib", paste0("safety.viz-", strVersion), "safety.viz.js",
      package = "gsm.safety"
    ))
  )
})

test_that("the legacy safetyCharts bridge is fully retired (#31, #41)", {
  expect_false("RenderSafetyChartsWidget" %in% getNamespaceExports("gsm.safety"))
  expect_false("MakeExampleData" %in% getNamespaceExports("gsm.safety"))

  # The paneled outlier variant had no safety.viz module and is gone for good.
  expect_identical(
    system.file(
      "workflow", "4_modules", "paneled_outlier_explorer.yaml",
      package = "gsm.safety"
    ),
    "",
    info = "paneled_outlier_explorer"
  )

  # ae_explorer came back in #41, but as a Widget_* workflow — every surviving
  # module workflow must render through this package's own steps, never the
  # retired bridge. Since #61 there are two kinds: the widget modules render
  # through gsm.safety::Widget_*, and the census report renders through
  # gsm.safety::Report_*.
  chrWorkflows <- list.files(
    system.file("workflow", "4_modules", package = "gsm.safety"),
    pattern = "[.]yaml$",
    full.names = TRUE
  )
  for (strWorkflow in chrWorkflows) {
    strYAML <- paste(readLines(strWorkflow, warn = FALSE), collapse = "\n")
    expect_true(
      grepl("gsm.safety::Widget_", strYAML, fixed = TRUE) ||
        grepl("gsm.safety::Report_", strYAML, fixed = TRUE),
      info = basename(strWorkflow)
    )
    expect_false(
      grepl("safetyCharts|RenderSafetyChartsWidget", strYAML),
      info = basename(strWorkflow)
    )
  }
})
