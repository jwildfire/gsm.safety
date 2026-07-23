# Guards for the standalone example pages (#43).
#
# The nine Example_*.Rmd pages are the package's showcase surface: every gallery
# thumbnail and README link lands on one. They render outside pkgdown's template
# (gsm.utils::build_assets() renders them with rmarkdown and drops the HTML into
# pkgdown/assets/examples/), so their chrome, navigation, and workflow listings
# are the package's own responsibility. These tests hold that wiring together.
#
# pkgdown/ is .Rbuildignore'd, so everything here skips under R CMD check and
# runs under devtools::test() — the same contract as the gallery tests.

strExamplesDir <- function() {
  strPath <- testthat::test_path("..", "..", "pkgdown", "menus", "examples")
  skip_if_not(dir.exists(strPath), "pkgdown/ not available in this check context")
  strPath
}

# Source the shared helpers into a private environment so the tests exercise the
# same functions the pages call, without leaking them into the test namespace.
envExampleUtil <- function() {
  strDir <- strExamplesDir()
  strUtil <- file.path(strDir, "util", "example-page.R")
  expect_true(file.exists(strUtil))
  env <- new.env(parent = globalenv())
  sys.source(strUtil, envir = env)
  env
}

chrPageFiles <- function(strDir) {
  list.files(strDir, pattern = "^Example_.*[.]Rmd$", full.names = TRUE)
}

test_that("the example manifest is built from sibling front matter (#43)", {
  strDir <- strExamplesDir()
  env <- envExampleUtil()

  dfPages <- env$ExamplePages(strDir)

  expect_s3_class(dfPages, "data.frame")
  expect_identical(nrow(dfPages), length(chrPageFiles(strDir)))
  expect_true(all(c("file", "html", "title", "description", "index") %in% names(dfPages)))

  # Front matter is the single source of truth, so every page must supply it.
  expect_false(any(is.na(dfPages$index)))
  expect_true(all(nzchar(dfPages$title)))
  expect_true(all(nzchar(dfPages$description)))

  # The order the pages appear in the chip strip is the order gsm.utils uses to
  # build the navbar menu: ascending index. Contiguous 1..n keeps them in step.
  expect_identical(dfPages$index, sort(dfPages$index))
  expect_identical(dfPages$index, as.numeric(seq_len(nrow(dfPages))))

  expect_identical(dfPages$html, sub("[.]Rmd$", ".html", dfPages$file))
})

test_that("example page navigation is a closed ring (#43)", {
  strDir <- strExamplesDir()
  env <- envExampleUtil()
  dfPages <- env$ExamplePages(strDir)

  for (i in seq_len(nrow(dfPages))) {
    lNeighbors <- env$ExampleNeighbors(dfPages$file[i], dfPages)
    intPrev <- if (i == 1) nrow(dfPages) else i - 1
    intNext <- if (i == nrow(dfPages)) 1 else i + 1

    expect_identical(lNeighbors$prev$file, dfPages$file[intPrev], info = dfPages$file[i])
    expect_identical(lNeighbors$nxt$file, dfPages$file[intNext], info = dfPages$file[i])
  }
})

test_that("the chip strip links every example and marks the current page (#43)", {
  strDir <- strExamplesDir()
  env <- envExampleUtil()
  dfPages <- env$ExamplePages(strDir)

  for (i in seq_len(nrow(dfPages))) {
    strHTML <- env$ExampleHeader(dfPages$file[i], strDir)

    # The page's own description carries the lede, so it is written once.
    expect_match(strHTML, dfPages$description[i], fixed = TRUE, info = dfPages$file[i])

    # Every example is reachable from every other example.
    for (strHtmlFile in dfPages$html) {
      expect_match(strHTML, paste0('href="', strHtmlFile, '"'), fixed = TRUE)
    }

    # Exactly one chip is marked current, and it is this page's.
    chrCurrent <- regmatches(
      strHTML,
      gregexpr('<a href="[^"]+" aria-current="page">', strHTML)
    )[[1]]
    expect_length(chrCurrent, 1)
    expect_match(chrCurrent, dfPages$html[i], fixed = TRUE)
  }
})

test_that("the workflow disclosure embeds the shipped YAML verbatim and collapsed (#43)", {
  env <- envExampleUtil()
  strWorkflowDir <- testthat::test_path("..", "..", "inst", "workflow", "3_reports")
  skip_if_not(dir.exists(strWorkflowDir), "inst/workflow not available in this check context")

  for (strFile in list.files(strWorkflowDir, pattern = "[.]yaml$")) {
    strHTML <- env$ExampleWorkflow(strFile)
    chrYaml <- readLines(file.path(strWorkflowDir, strFile), warn = FALSE)

    # Collapsed by default: a <details> with no `open` attribute.
    expect_match(strHTML, "<details", fixed = TRUE, info = strFile)
    expect_no_match(strHTML, "<details[^>]*\\bopen\\b", info = strFile)
    expect_match(strHTML, strFile, fixed = TRUE, info = strFile)

    # Verbatim: every line of the shipped workflow reaches the page. A fenced
    # block inside the YAML would close the code fence early.
    expect_false(any(grepl("```", chrYaml, fixed = TRUE)), info = strFile)
    for (strLine in chrYaml[nzchar(chrYaml)]) {
      expect_true(grepl(strLine, strHTML, fixed = TRUE), info = paste(strFile, strLine))
    }
  }
})

test_that("every example page shows the workflow that renders its own widget (#43)", {
  strDir <- strExamplesDir()
  strWorkflowDir <- testthat::test_path("..", "..", "inst", "workflow", "3_reports")
  skip_if_not(dir.exists(strWorkflowDir), "inst/workflow not available in this check context")

  for (strPage in chrPageFiles(strDir)) {
    strText <- paste(readLines(strPage, warn = FALSE), collapse = "\n")

    # The page names its workflow exactly once, via the shared helper.
    chrCalls <- regmatches(
      strText,
      gregexpr('ExampleWorkflow\\("[^"]+"\\)', strText)
    )[[1]]
    expect_length(chrCalls, 1)
    strWorkflow <- sub('^ExampleWorkflow\\("(.*)"\\)$', "\\1", chrCalls)
    expect_true(
      file.exists(file.path(strWorkflowDir, strWorkflow)),
      info = paste(basename(strPage), strWorkflow)
    )

    # ...and that workflow must render the same widget the page demonstrates,
    # so a page can never advertise a workflow for a different chart.
    chrWidgets <- unique(regmatches(strText, gregexpr("Widget_[A-Za-z]+", strText))[[1]])
    expect_length(chrWidgets, 1)

    lWorkflow <- yaml::read_yaml(file.path(strWorkflowDir, strWorkflow))
    chrSteps <- vapply(
      lWorkflow$steps,
      function(lStep) if (is.null(lStep$name)) "" else as.character(lStep$name),
      character(1)
    )
    expect_true(
      paste0("gsm.safety::", chrWidgets) %in% chrSteps,
      info = paste(basename(strPage), strWorkflow, chrWidgets)
    )
  }
})

test_that("every example page is wired to the shared chrome (#43)", {
  strDir <- strExamplesDir()

  for (strPage in chrPageFiles(strDir)) {
    strText <- paste(readLines(strPage, warn = FALSE), collapse = "\n")
    strInfo <- basename(strPage)

    expect_match(strText, "before_body: util/example-chrome.html", fixed = TRUE, info = strInfo)
    expect_match(strText, 'source("util/example-page.R")', fixed = TRUE, info = strInfo)
    expect_match(strText, "ExampleHeader()", fixed = TRUE, info = strInfo)
    expect_match(strText, "ExampleFooter()", fixed = TRUE, info = strInfo)

    # Page-local <style> blocks are what the shared chrome replaced; a new one
    # would quietly fork the styling again.
    expect_no_match(strText, "<style>", fixed = TRUE, info = strInfo)
  }
})

test_that("every exported widget has an example page (#43)", {
  strDir <- strExamplesDir()

  chrPageWidgets <- vapply(chrPageFiles(strDir), function(strPage) {
    strText <- paste(readLines(strPage, warn = FALSE), collapse = "\n")
    unique(regmatches(strText, gregexpr("Widget_[A-Za-z]+", strText))[[1]])[1]
  }, character(1))

  chrExported <- grep("^Widget_", getNamespaceExports("gsm.safety"), value = TRUE)
  expect_setequal(unname(chrPageWidgets), chrExported)
})

test_that("the shared chrome navigates back to the rest of the site (#43)", {
  strDir <- strExamplesDir()
  strChrome <- file.path(strDir, "util", "example-chrome.html")
  expect_true(file.exists(strChrome))
  strText <- paste(readLines(strChrome, warn = FALSE), collapse = "\n")

  # Relative hrefs: the site is also deployed under /dev/ and /pr/{N}/ previews.
  expect_match(strText, '"../index.html"', fixed = TRUE)
  expect_match(strText, '"../reference/index.html"', fixed = TRUE)
  expect_no_match(strText, "https://jwildfire.github.io/gsm.safety", fixed = TRUE)
  expect_match(strText, "https://github.com/jwildfire/gsm.safety", fixed = TRUE)
  expect_match(strText, "https://jwildfire.github.io/safety.viz/", fixed = TRUE)
})

test_that("the provenance line reports the vendored safety.viz bundle (#43)", {
  env <- envExampleUtil()

  strBundle <- env$ExampleBundleVersion()
  expect_match(strBundle, "^[0-9]+[.][0-9]+[.][0-9]+$")

  strLibDir <- testthat::test_path("..", "..", "inst", "htmlwidgets", "lib")
  skip_if_not(dir.exists(strLibDir), "inst/htmlwidgets not available in this check context")
  expect_identical(
    list.files(strLibDir, pattern = "^safety[.]viz-"),
    paste0("safety.viz-", strBundle)
  )

  strProvenance <- env$ExampleProvenance()
  expect_match(strProvenance, as.character(utils::packageVersion("gsm.safety")), fixed = TRUE)
  expect_match(strProvenance, strBundle, fixed = TRUE)
})
