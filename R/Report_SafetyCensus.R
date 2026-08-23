#' Render the census report
#'
#' Writes the safety census as one self-contained HTML page from the tables the
#' report workflow's other steps assembled. It is the last step of
#' `inst/workflow/4_modules/safety_census.yaml`, and like every step before it,
#' it reads: it lays out figures it did not compute.
#'
#' @section What the page holds:
#'
#' Each section of figures the workflow declares, every figure beside the
#' denominator its own metric published; then the coverage table, **only if a
#' coverage figure was published**; then what every metric published, verbatim,
#' including the metrics that published nothing.
#'
#' Nothing on the page flags. There is no flag column, no colour carrying a
#' verdict and no cut-point — D0023.3, and the same rule the metrics follow by
#' declaring no threshold and publishing an empty flag.
#'
#' @param dfFigures `data.frame` From [Report_CensusFigures()].
#' @param dfCoverage `data.frame` From [Report_CensusCoverage()]. Zero rows —
#'   or `NULL` — renders no coverage section at all, rather than an empty one.
#' @param dfProvenance `data.frame` From [Report_CensusProvenance()]. `NULL`
#'   renders no provenance section.
#' @param dfResults `data.frame` The metric results, read only for the study
#'   identifier and snapshot date in the page header.
#' @param strTitle `character` Page title. Default: `"Safety Census"`.
#' @param strOutputDir `character` Directory to write into. Default:
#'   [getwd()].
#' @param strOutputFile `character` File name. Default: a name built from the
#'   study and snapshot date.
#'
#' @return The path of the written page, invisibly.
#'
#' @examples
#' dfFigures <- data.frame(
#'   Section = "Population", ID = "saf0004", Figure = "Deaths (Study)",
#'   Value = 13, Unit = NA_character_, Denominator = 762,
#'   DenominatorLabel = "Enrolled Participant"
#' )
#' strPath <- Report_SafetyCensus(dfFigures, strOutputDir = tempdir())
#'
#' @export
Report_SafetyCensus <- function(
    dfFigures,
    dfCoverage = NULL,
    dfProvenance = NULL,
    dfResults = NULL,
    strTitle = "Safety Census",
    strOutputDir = getwd(),
    strOutputFile = NULL) {
  gsm.core::stop_if(
    cnd = !is.data.frame(dfFigures),
    message = "dfFigures is not a data.frame"
  )
  .RequireColumns(
    dfFigures,
    c("Section", "ID", "Figure", "Value", "Unit", "Denominator", "DenominatorLabel"),
    "dfFigures"
  )
  gsm.core::stop_if(
    cnd = !(is.character(strOutputDir) && length(strOutputDir) == 1),
    message = "strOutputDir is not a length-1 character"
  )

  strStudyID <- .CensusStudyID(dfResults)
  strSnapshot <- .CensusSnapshotDate(dfResults)

  if (is.null(strOutputFile)) {
    strOutputFile <- paste(
      c(
        "safety_census",
        gsub("[^[:alnum:]]", "", strStudyID),
        gsub("[^[:alnum:]]", "", strSnapshot)
      )[nzchar(c("safety_census", strStudyID, strSnapshot))],
      collapse = "_"
    )
  }
  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }
  strOutputPath <- file.path(
    normalizePath(strOutputDir, winslash = "/"), strOutputFile
  )

  writeLines(
    .CensusPageHtml(
      dfFigures = dfFigures,
      dfCoverage = dfCoverage,
      dfProvenance = dfProvenance,
      strTitle = strTitle,
      strStudyID = strStudyID,
      strSnapshot = strSnapshot
    ),
    strOutputPath,
    useBytes = TRUE
  )

  invisible(normalizePath(strOutputPath, winslash = "/"))
}

#' The census page as one HTML string
#'
#' @inheritParams Report_SafetyCensus
#' @param strStudyID `character` Study identifier for the header.
#' @param strSnapshot `character` Snapshot date for the header.
#'
#' @return `character(1)` — a complete, self-contained HTML document.
#'
#' @keywords internal
.CensusPageHtml <- function(
    dfFigures, dfCoverage, dfProvenance, strTitle, strStudyID, strSnapshot) {
  lBody <- list(
    htmltools::tags$h1(strTitle),
    htmltools::tags$p(
      class = "subtitle",
      paste(
        c(
          if (nzchar(strStudyID)) paste("Study:", strStudyID),
          if (nzchar(strSnapshot)) paste("Snapshot date:", strSnapshot)
        ),
        collapse = " \u00b7 "
      )
    ),
    htmltools::tags$p(
      class = "note",
      paste(
        "Every number on this page was published by a census metric and is",
        "read here unchanged. Each figure is shown beside the denominator its",
        "own metric published, and what each metric published is recorded",
        "verbatim at the foot of the page.",
        "No number here flags: these metrics publish an empty flag, and a",
        "result arriving with a flag is refused rather than presented."
      )
    )
  )

  for (strSection in unique(dfFigures$Section)) {
    dfSection <- dfFigures[dfFigures$Section == strSection, , drop = FALSE]
    if (nrow(dfSection) == 0) next
    lBody <- c(lBody, list(
      htmltools::tags$h2(strSection),
      .CensusFigureTable(dfSection)
    ))
    if (any(!is.na(dfSection$Unit))) {
      lBody <- c(lBody, list(htmltools::tags$p(
        class = "note",
        paste(
          "Published by the metric as participant-days and presented here in",
          "years. Both numbers are on this page: the days are under",
          "\u201cWhat the metrics published\u201d below."
        )
      )))
    }
  }

  # Absent, not empty. A study with no coverage figure gets no coverage
  # section: an empty table would read as a study with no data rather than a
  # report with no metric.
  if (!is.null(dfCoverage) && is.data.frame(dfCoverage) && nrow(dfCoverage) > 0) {
    lBody <- c(lBody, list(
      htmltools::tags$h2("Data coverage"),
      .CensusCoverageTable(dfCoverage)
    ))
  }

  if (!is.null(dfProvenance) && is.data.frame(dfProvenance) &&
    nrow(dfProvenance) > 0) {
    lBody <- c(lBody, list(
      htmltools::tags$h2("What the metrics published"),
      .CensusProvenanceTable(dfProvenance)
    ))
  }

  paste0(
    "<!DOCTYPE html>\n",
    as.character(htmltools::tags$html(
      lang = "en",
      htmltools::tags$head(
        htmltools::tags$meta(charset = "utf-8"),
        htmltools::tags$meta(
          name = "viewport", content = "width=device-width, initial-scale=1"
        ),
        htmltools::tags$title(strTitle),
        htmltools::tags$style(htmltools::HTML(.CensusPageCss()))
      ),
      htmltools::tags$body(htmltools::tags$main(lBody))
    )),
    "\n"
  )
}

#' The figures table
#' @keywords internal
.CensusFigureTable <- function(dfSection) {
  .CensusTable(
    chrHeaders = c("Figure", "Value", "Denominator", "Denominator counts"),
    lRows = lapply(seq_len(nrow(dfSection)), function(i) {
      list(
        dfSection$Figure[i],
        .CensusValue(dfSection$Value[i], dfSection$Unit[i]),
        .CensusNumber(dfSection$Denominator[i]),
        dfSection$DenominatorLabel[i]
      )
    }),
    chrClasses = c("", "num", "num", "")
  )
}

#' The coverage table
#' @keywords internal
.CensusCoverageTable <- function(dfCoverage) {
  .CensusTable(
    chrHeaders = c("Figure", "Group", "Participants with a result", "Expected"),
    lRows = lapply(seq_len(nrow(dfCoverage)), function(i) {
      list(
        dfCoverage$Figure[i],
        dfCoverage$Group[i],
        .CensusNumber(dfCoverage$Participants[i]),
        .CensusNumber(dfCoverage$Expected[i])
      )
    }),
    chrClasses = c("", "", "num", "num")
  )
}

#' The provenance table
#' @keywords internal
.CensusProvenanceTable <- function(dfProvenance) {
  .CensusTable(
    chrHeaders = c("Metric", "Figure", "Numerator", "Denominator", "Status"),
    lRows = lapply(seq_len(nrow(dfProvenance)), function(i) {
      list(
        dfProvenance$ID[i],
        dfProvenance$Figure[i],
        .CensusNumber(dfProvenance$Numerator[i]),
        .CensusNumber(dfProvenance$Denominator[i]),
        dfProvenance$Status[i]
      )
    }),
    chrClasses = c("id", "", "num", "num", "")
  )
}

#' One HTML table
#' @keywords internal
.CensusTable <- function(chrHeaders, lRows, chrClasses) {
  htmltools::tags$table(
    htmltools::tags$thead(htmltools::tags$tr(
      lapply(seq_along(chrHeaders), function(j) {
        htmltools::tags$th(
          class = if (nzchar(chrClasses[j])) chrClasses[j] else NULL,
          chrHeaders[j]
        )
      })
    )),
    htmltools::tags$tbody(
      lapply(lRows, function(lCells) {
        htmltools::tags$tr(lapply(seq_along(lCells), function(j) {
          strCell <- lCells[[j]]
          if (is.na(strCell)) strCell <- "\u2014"
          htmltools::tags$td(
            class = if (nzchar(chrClasses[j])) chrClasses[j] else NULL,
            as.character(strCell)
          )
        }))
      })
    )
  )
}

#' A figure and, where it has one, its unit
#' @keywords internal
.CensusValue <- function(nValue, strUnit) {
  strValue <- .CensusNumber(nValue)
  if (is.na(strUnit) || !nzchar(strUnit)) {
    return(strValue)
  }
  paste(strValue, strUnit)
}

#' A number as a reader reads it
#' @keywords internal
.CensusNumber <- function(nValue) {
  if (length(nValue) != 1 || is.na(nValue) || !is.finite(nValue)) {
    return(NA_character_)
  }
  formatC(
    nValue,
    format = "f",
    digits = if (isTRUE(all.equal(nValue, round(nValue)))) 0L else 1L,
    big.mark = ","
  )
}

#' The study identifier the results carry
#' @keywords internal
.CensusStudyID <- function(dfResults) {
  .CensusFirstValue(dfResults, c("StudyID", "GroupID"))
}

#' The snapshot date the results carry
#' @keywords internal
.CensusSnapshotDate <- function(dfResults) {
  .CensusFirstValue(dfResults, "SnapshotDate")
}

#' The first non-missing value of the first column present
#' @keywords internal
.CensusFirstValue <- function(dfResults, chrCols) {
  if (!is.data.frame(dfResults) || nrow(dfResults) == 0) {
    return("")
  }
  for (strCol in chrCols) {
    if (!(strCol %in% names(dfResults))) next
    chrValue <- as.character(dfResults[[strCol]])
    chrValue <- chrValue[!is.na(chrValue) & nzchar(chrValue)]
    if (length(chrValue)) {
      return(chrValue[1])
    }
  }
  ""
}

#' The page's styling
#'
#' Deliberately colourless where a number is concerned. Nothing on this page
#' carries a verdict, so nothing on it is coloured to suggest one.
#'
#' @keywords internal
.CensusPageCss <- function() {
  paste(
    "html { -webkit-text-size-adjust: 100%; }",
    "body { margin: 0; background: #ffffff; color: #1a1a1a;",
    "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;",
    "  line-height: 1.5; }",
    "main { max-width: 54rem; margin: 0 auto; padding: 2rem 1rem 4rem; }",
    "h1 { font-size: 1.75rem; margin: 0 0 0.25rem; }",
    "h2 { font-size: 1.15rem; margin: 2.25rem 0 0.5rem;",
    "  padding-bottom: 0.25rem; border-bottom: 1px solid #d8d8d8; }",
    ".subtitle { margin: 0 0 1rem; color: #4a4a4a; }",
    ".note { color: #4a4a4a; font-size: 0.9rem; margin: 0.5rem 0 1.25rem; }",
    "table { width: 100%; border-collapse: collapse; margin: 0.25rem 0 0.5rem;",
    "  font-variant-numeric: tabular-nums; }",
    "th, td { text-align: left; padding: 0.45rem 0.6rem;",
    "  border-bottom: 1px solid #ececec; }",
    "th { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.04em;",
    "  color: #5a5a5a; border-bottom: 1px solid #c8c8c8; }",
    "td.num, th.num { text-align: right; }",
    "td.id { font-family: ui-monospace, SFMono-Regular, Menlo, monospace;",
    "  font-size: 0.85rem; }",
    "@media (max-width: 40rem) { main { padding: 1.25rem 0.75rem 3rem; }",
    "  th, td { padding: 0.4rem 0.35rem; } }",
    sep = "\n"
  )
}
