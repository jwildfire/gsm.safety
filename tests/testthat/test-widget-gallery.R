strGalleryModules <- function() {
  c(
    Widget_Histogram = "histogram",
    Widget_ShiftPlot = "shift-plot",
    Widget_DeltaDelta = "delta-delta",
    Widget_ResultsOverTime = "results-over-time",
    Widget_OutlierExplorer = "outlier-explorer",
    Widget_AeTimelines = "ae-timelines",
    Widget_AeExplorer = "ae-explorer",
    Widget_HepExplorer = "hep-explorer",
    Widget_QtExplorer = "qt-explorer"
  )
}

# The gallery lives in README.md, which pkgdown renders as the site home page.
strReadme <- function() {
  strPath <- testthat::test_path("..", "..", "README.md")
  skip_if_not(file.exists(strPath), "README.md not available in this check context")
  paste(readLines(strPath, warn = FALSE), collapse = "\n")
}

test_that("every exported widget has a gallery thumbnail (#28)", {
  strPath <- testthat::test_path("..", "..", "man", "figures", "widgets")
  skip_if_not(dir.exists(strPath), "man/figures not available in this check context")

  chrModules <- strGalleryModules()
  for (strModule in chrModules) {
    strThumb <- file.path(strPath, paste0(strModule, ".png"))
    expect_true(file.exists(strThumb), info = strModule)
    # A vendored capture, not an empty placeholder.
    expect_gt(file.size(strThumb), 10000)
  }

  # No orphans: a retired widget must not leave its thumbnail behind.
  chrOnDisk <- sub("[.]png$", "", list.files(strPath, pattern = "[.]png$"))
  expect_setequal(chrOnDisk, unname(chrModules))
})

test_that("the gallery covers exactly the exported Widget_* functions (#28)", {
  chrExported <- grep("^Widget_", getNamespaceExports("gsm.safety"), value = TRUE)
  expect_setequal(chrExported, names(strGalleryModules()))
})

test_that("the README gallery links every widget to its example page (#28)", {
  strReadmeText <- strReadme()

  for (strWidget in names(strGalleryModules())) {
    strExample <- sub("^Widget_", "Example_", strWidget)
    expect_match(
      strReadmeText,
      paste0("examples/", strExample, ".html"),
      fixed = TRUE,
      info = strWidget
    )
  }
})

test_that("every gallery thumbnail is referenced by the README (#28)", {
  strReadmeText <- strReadme()

  for (strModule in strGalleryModules()) {
    expect_match(
      strReadmeText,
      paste0("man/figures/widgets/", strModule, ".png"),
      fixed = TRUE,
      info = strModule
    )
  }
})

test_that("the README documents how to refresh the thumbnails (#28)", {
  strReadmeText <- strReadme()
  expect_match(strReadmeText, "tools/vendor-widget-thumbnails.sh", fixed = TRUE)

  strScript <- testthat::test_path("..", "..", "tools", "vendor-widget-thumbnails.sh")
  skip_if_not(file.exists(strScript), "tools/ not available in this check context")
  strScriptText <- paste(readLines(strScript, warn = FALSE), collapse = "\n")

  # The script's module list drives what gets vendored; keep it in step with
  # the widgets so a new binding cannot ship without a thumbnail.
  for (strModule in strGalleryModules()) {
    expect_match(strScriptText, paste0("\n  ", strModule, "\n"), info = strModule)
  }
})
