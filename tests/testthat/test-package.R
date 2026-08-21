test_that("package metadata is available (#31)", {
  expect_equal(utils::packageDescription("gsm.safety")$Package, "gsm.safety")
})

test_that("gsm.safety exports the eleven safety.viz widgets plus data, report and metric helpers (#31, #41, #42, #45, #49)", {
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
      "ExampleData",
      "SaveWidgetReport",
      # The 2_metrics phase: one Input_* step per participant-level metric.
      "Input_HysLaw",
      "Input_QtProlongation",
      "Input_SafetyAE",
      # The Safety overview's denominators.
      "SafetyCensus"
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
    "hepWaterfall", "nepExplorer"
  )
  # Deferred wraps: every entry MUST cite its filed requirement (the parity
  # rule's single-release clause) and mirror .github/parity-allowlist.yaml.
  chrDeferred <- c(
    # Multi-domain payload + selection semantics need design first:
    # https://github.com/jwildfire/obot.roadmap/issues/165
    "participantProfile",
    # Two data frames (ADAE-shaped events + ADSL-shaped population) do not fit
    # the single-dfResults widget contract; same design gate:
    # https://github.com/jwildfire/obot.roadmap/issues/165
    "timeToEvent"
  )
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
  expect_length(chrBindings, length(chrModules))
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
    Widget_NepExplorer = list(slug = "nep-explorer", workflow = "nep_explorer")
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
  # report workflow must render through a widget, never the retired bridge.
  chrWorkflows <- list.files(
    system.file("workflow", "4_modules", package = "gsm.safety"),
    pattern = "[.]yaml$",
    full.names = TRUE
  )
  for (strWorkflow in chrWorkflows) {
    strYAML <- paste(readLines(strWorkflow, warn = FALSE), collapse = "\n")
    expect_match(
      strYAML,
      "gsm.safety::Widget_",
      fixed = TRUE,
      info = basename(strWorkflow)
    )
    expect_false(
      grepl("safetyCharts|RenderSafetyChartsWidget", strYAML),
      info = basename(strWorkflow)
    )
  }
})
