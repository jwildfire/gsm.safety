# Shared helpers for the standalone example pages (#43).
#
# Sourced by each Example_*.Rmd; never rendered as a page of its own, because
# gsm.utils::build_assets() globs *.Rmd non-recursively in the menu directory.
#
# Everything the pages have in common is generated here rather than pasted nine
# times: the navigation is derived from the sibling pages' own front matter, and
# the workflow listing is read from the installed package. Adding a chart wires
# itself into every other page's navigation, and neither the nav ring nor the
# displayed YAML can drift from what actually ships.
#
# Each helper returns an HTML string; pages emit it from a `results = "asis"`
# chunk. Returning rather than printing keeps them testable — see
# tests/testthat/test-example-pages.R.

# The ordered manifest of example pages, read from their YAML front matter.
# Sorted the way gsm.utils::construct_menu() sorts the navbar menu, so the chip
# strip and the site navigation always agree.
ExamplePages <- function(strDir = ".") {
  chrFiles <- list.files(strDir, pattern = "^Example_.*[.]Rmd$")
  if (!length(chrFiles)) {
    stop("No Example_*.Rmd pages found in ", normalizePath(strDir, mustWork = FALSE))
  }

  lMeta <- lapply(chrFiles, function(strFile) {
    rmarkdown::yaml_front_matter(file.path(strDir, strFile))
  })

  strField <- function(strName) {
    vapply(lMeta, function(l) {
      if (is.null(l[[strName]])) "" else as.character(l[[strName]])[1]
    }, character(1))
  }

  dfPages <- data.frame(
    file = chrFiles,
    html = sub("[.]Rmd$", ".html", chrFiles),
    title = strField("title"),
    description = strField("description"),
    index = suppressWarnings(as.numeric(strField("index"))),
    stringsAsFactors = FALSE
  )
  dfPages$index[is.na(dfPages$index)] <- Inf

  dfPages <- dfPages[order(dfPages$index, dfPages$title), , drop = FALSE]
  rownames(dfPages) <- NULL
  dfPages
}

# The pages either side of `strFile`, wrapping at both ends so the pager is a
# closed ring rather than a path with two dead ends.
ExampleNeighbors <- function(strFile, dfPages = ExamplePages()) {
  intPos <- match(strFile, dfPages$file)
  if (is.na(intPos)) {
    stop("'", strFile, "' is not one of the example pages.")
  }

  intCount <- nrow(dfPages)
  list(
    prev = dfPages[if (intPos == 1) intCount else intPos - 1, , drop = FALSE],
    nxt = dfPages[if (intPos == intCount) 1 else intPos + 1, , drop = FALSE]
  )
}

# The page currently being knitted. Under gsm.utils::render_rmd() the input is
# copied to an intermediates directory, so match on the file name alone.
ExampleCurrentFile <- function() {
  strFile <- tryCatch(knitr::current_input(), error = function(e) NULL)
  if (is.null(strFile) || !nzchar(strFile)) {
    stop("ExampleHeader() and ExampleFooter() must be called from a knitted example page.")
  }
  basename(strFile)
}

# The vendored safety.viz bundle. Read from the library directory the widget
# dependencies point at, so it reports what the charts on the page actually ran.
ExampleBundleVersion <- function() {
  chrBundles <- list.files(
    system.file("htmlwidgets", "lib", package = "gsm.safety"),
    pattern = "^safety[.]viz-"
  )
  if (length(chrBundles) != 1) {
    stop("Expected exactly one vendored safety.viz bundle, found ", length(chrBundles), ".")
  }
  sub("^safety[.]viz-", "", chrBundles)
}

ExampleProvenance <- function() {
  sprintf(
    "gsm.safety %s · safety.viz %s · rendered %s",
    utils::packageVersion("gsm.safety"),
    ExampleBundleVersion(),
    format(Sys.Date(), "%Y-%m-%d")
  )
}

# Lede, provenance, and the chip strip linking every example, sitting directly
# under rmarkdown's title block.
ExampleHeader <- function(strFile = ExampleCurrentFile(), strDir = ".") {
  dfPages <- ExamplePages(strDir)
  intPos <- match(strFile, dfPages$file)
  if (is.na(intPos)) {
    stop("'", strFile, "' is not one of the example pages.")
  }

  chrChips <- sprintf(
    '<a href="%s"%s>%s</a>',
    dfPages$html,
    ifelse(seq_len(nrow(dfPages)) == intPos, ' aria-current="page"', ""),
    htmltools::htmlEscape(dfPages$title)
  )

  paste0(
    '<p class="gs-lede">', htmltools::htmlEscape(dfPages$description[intPos]), "</p>\n",
    '<p class="gs-meta">', htmltools::htmlEscape(ExampleProvenance()), "</p>\n",
    '<nav class="gs-chips" aria-label="All examples">\n',
    paste(chrChips, collapse = "\n"),
    "\n</nav>\n"
  )
}

# The report workflow that renders this page's chart, shown in full but
# collapsed. Read from the installed package so the listing is the shipped file
# rather than a copy of it.
ExampleWorkflow <- function(strWorkflow) {
  strPath <- system.file("workflow", "3_reports", strWorkflow, package = "gsm.safety")
  if (!nzchar(strPath)) {
    stop("No report workflow named '", strWorkflow, "' ships with gsm.safety.")
  }

  # A blank line either side of the fence takes pandoc out of raw-HTML mode, so
  # the YAML is parsed as a code block and picks up syntax highlighting.
  paste0(
    '<details class="gs-workflow">\n',
    "<summary>The full <code>", strWorkflow, "</code> workflow</summary>\n\n",
    "```yaml\n",
    paste(readLines(strPath, warn = FALSE), collapse = "\n"),
    "\n```\n\n",
    "</details>\n"
  )
}

ExampleFooter <- function(strFile = ExampleCurrentFile(), strDir = ".") {
  lNeighbors <- ExampleNeighbors(strFile, ExamplePages(strDir))

  strLink <- function(dfPage, strClass, strDir) {
    sprintf(
      '<a class="%s" href="%s"><span class="gs-pager-dir">%s</span><span class="gs-pager-title">%s</span></a>',
      strClass, dfPage$html, strDir, htmltools::htmlEscape(dfPage$title)
    )
  }

  paste0(
    '<nav class="gs-pager" aria-label="Example navigation">\n',
    strLink(lNeighbors$prev, "gs-pager-prev", "← Previous"), "\n",
    strLink(lNeighbors$nxt, "gs-pager-next", "Next →"), "\n",
    "</nav>\n"
  )
}
