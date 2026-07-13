test_that("package metadata is available (#31)", {
  expect_equal(utils::packageDescription("gsm.safety")$Package, "gsm.safety")
})

test_that("gsm.safety exports the seven safety.viz widgets plus data and report helpers (#31)", {
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
      "ExampleData",
      "SaveWidgetReport"
    )
  )
})

test_that("every widget ships its htmlwidgets binding, dependency yaml, schema, and report workflow (#31, #38)", {
  lWidgets <- list(
    Widget_Histogram = list(slug = "histogram", workflow = "safety_histogram"),
    Widget_ShiftPlot = list(slug = "shift-plot", workflow = "safety_shift_plot"),
    Widget_DeltaDelta = list(slug = "delta-delta", workflow = "safety_delta_delta"),
    Widget_ResultsOverTime = list(slug = "results-over-time", workflow = "safety_results_over_time"),
    Widget_OutlierExplorer = list(slug = "outlier-explorer", workflow = "safety_outlier_explorer"),
    Widget_AeTimelines = list(slug = "ae-timelines", workflow = "ae_timelines"),
    Widget_HepExplorer = list(slug = "hep-explorer", workflow = "hep_explorer")
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
        "workflow", "3_reports", paste0(lWidget$workflow, ".yaml"),
        package = "gsm.safety"
      )),
      info = strWidget
    )
  }

  expect_true(
    nzchar(system.file(
      "htmlwidgets", "lib", "safety.viz-1.2.0", "safety.viz.js",
      package = "gsm.safety"
    ))
  )
})

test_that("the legacy safetyCharts bridge is fully retired (#31)", {
  expect_false("RenderSafetyChartsWidget" %in% getNamespaceExports("gsm.safety"))
  expect_false("MakeExampleData" %in% getNamespaceExports("gsm.safety"))
  for (strLegacy in c("ae_explorer", "paneled_outlier_explorer")) {
    expect_identical(
      system.file(
        "workflow", "3_reports", paste0(strLegacy, ".yaml"),
        package = "gsm.safety"
      ),
      "",
      info = strLegacy
    )
  }
})
