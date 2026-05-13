#' Create AE Explorer report settings from a workr spec
#'
#' @param lSpec A `workr` workflow spec for the AE Explorer report.
#'
#' @return A list of domain mappings and known gaps for AE Explorer.
#' @export
MakeAeExplorerSettings <- function(lSpec) {
  if (is.null(lSpec$Mapped_SUBJ) || is.null(lSpec$Mapped_AE)) {
    stop("AE Explorer requires Mapped_SUBJ and Mapped_AE specs.", call. = FALSE)
  }

  list(
    domains = list(
      dm = "Mapped_SUBJ",
      aes = "Mapped_AE"
    ),
    settings = list(
      dm = list(
        id_col = "subjid",
        treatment_col = NULL
      ),
      aes = list(
        id_col = "subjid",
        term_col = "mdrpt_nsv",
        bodsys_col = "mdrsoc_nsv"
      )
    ),
    optional_filters = list(
      seriousness = "aeser",
      severity = "aetoxgr",
      relationship = "aerel"
    ),
    gaps = c(
      treatment_col = "No clear treatment/group field identified in current Mapped_SUBJ.",
      aeout = "No current Mapped_AE outcome field identified."
    )
  )
}

#' Create an AE Explorer report manifest
#'
#' @param lData A named list of workflow data frames.
#' @param lSettings AE Explorer settings from [MakeAeExplorerSettings()].
#' @param lMeta Workflow metadata.
#'
#' @return A manifest list describing the AE Explorer report configuration.
#' @export
MakeAeExplorerManifest <- function(lData, lSettings, lMeta = list()) {
  required_domains <- unlist(lSettings$domains, use.names = FALSE)
  missing_domains <- setdiff(required_domains, names(lData))
  if (length(missing_domains) > 0) {
    stop(
      "AE Explorer missing required domain(s): ",
      paste(missing_domains, collapse = ", "),
      call. = FALSE
    )
  }

  aes_settings <- lSettings$settings$aes
  missing_columns <- required_columns(
    lData[[lSettings$domains$aes]],
    c(aes_settings$id_col, aes_settings$term_col, aes_settings$bodsys_col),
    lSettings$domains$aes
  )
  if (length(missing_columns) > 0) {
    stop(paste(missing_columns, collapse = "\n"), call. = FALSE)
  }

  list(
    report_id = lMeta$ID %||% "ae_explorer",
    report_type = lMeta$Type %||% "Report",
    output = lMeta$Output %||% "html",
    domains = lSettings$domains,
    settings = lSettings$settings,
    optional_filters = lSettings$optional_filters,
    gaps = lSettings$gaps,
    status = "ready"
  )
}

#' Render a static AE Explorer report
#'
#' This first report artifact is intentionally lightweight: it validates the
#' mapped AE inputs, summarizes adverse events by preferred term and body
#' system, and writes a static HTML report that can be attached to a workflow
#' run or shown in pkgdown examples. It is a report-shaped bridge toward the
#' eventual interactive AE Explorer implementation.
#'
#' @param lData A named list containing `Mapped_SUBJ` and `Mapped_AE` data frames.
#' @param lSettings AE Explorer settings from [MakeAeExplorerSettings()].
#' @param lManifest AE Explorer manifest from [MakeAeExplorerManifest()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when
#'   absent.
#'
#' @return A list with the report path, HTML, manifest, and summary tables.
#' @export
Report_AE_Explorer <- function(lData,
                               lSettings,
                               lManifest,
                               strOutputDir = getwd(),
                               strOutputFile = "ae_explorer") {
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }

  aes_domain <- lSettings$domains$aes
  dm_domain <- lSettings$domains$dm
  df_ae <- lData[[aes_domain]]
  df_dm <- lData[[dm_domain]]

  aes_settings <- lSettings$settings$aes
  dm_settings <- lSettings$settings$dm

  missing_columns <- c(
    required_columns(df_dm, dm_settings$id_col, dm_domain),
    required_columns(df_ae, c(aes_settings$id_col, aes_settings$term_col, aes_settings$bodsys_col), aes_domain)
  )
  if (length(missing_columns) > 0) {
    stop(paste(missing_columns, collapse = "\n"), call. = FALSE)
  }

  term_summary <- count_values(df_ae, aes_settings$term_col)
  body_system_summary <- count_values(df_ae, aes_settings$bodsys_col)
  subject_count <- length(unique(df_dm[[dm_settings$id_col]]))
  ae_subject_count <- length(unique(df_ae[[aes_settings$id_col]]))

  html <- build_ae_explorer_html(
    report_id = lManifest$report_id %||% "ae_explorer",
    subject_count = subject_count,
    ae_subject_count = ae_subject_count,
    ae_count = nrow(df_ae),
    term_summary = term_summary,
    body_system_summary = body_system_summary,
    gaps = lManifest$gaps
  )

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(strOutputDir, strOutputFile)
  writeLines(html, strOutputPath, useBytes = TRUE)

  list(
    path = normalizePath(strOutputPath, winslash = "/", mustWork = FALSE),
    html = html,
    manifest = lManifest,
    summaries = list(
      terms = term_summary,
      body_systems = body_system_summary
    )
  )
}

#' Create small example data for the AE Explorer report
#'
#' @return A named list containing `Mapped_SUBJ` and `Mapped_AE` example data.
#' @export
MakeAeExplorerExampleData <- function() {
  list(
    Mapped_SUBJ = data.frame(
      subjid = sprintf("SUBJ-%03d", 1:6),
      stringsAsFactors = FALSE
    ),
    Mapped_AE = data.frame(
      subjid = c("SUBJ-001", "SUBJ-001", "SUBJ-002", "SUBJ-003", "SUBJ-004", "SUBJ-006"),
      mdrpt_nsv = c("Headache", "Nausea", "Headache", "Fatigue", "Nausea", "Dizziness"),
      mdrsoc_nsv = c(
        "Nervous system disorders",
        "Gastrointestinal disorders",
        "Nervous system disorders",
        "General disorders",
        "Gastrointestinal disorders",
        "Nervous system disorders"
      ),
      aeser = c("N", "N", "N", "N", "Y", "N"),
      aetoxgr = c(1L, 1L, 2L, 1L, 3L, 1L),
      aerel = c("Possible", "Possible", "Unrelated", "Possible", "Probable", "Unrelated"),
      stringsAsFactors = FALSE
    )
  )
}

required_columns <- function(df, columns, domain) {
  columns <- columns[!is.na(columns) & nzchar(columns)]
  missing <- setdiff(columns, names(df))
  if (length(missing) == 0) {
    character()
  } else {
    paste0(domain, " is missing required column: ", missing)
  }
}

count_values <- function(df, column) {
  values <- df[[column]]
  values[is.na(values) | !nzchar(as.character(values))] <- "<Missing>"
  counts <- sort(table(values), decreasing = TRUE)
  data.frame(
    value = names(counts),
    n = as.integer(counts),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

build_ae_explorer_html <- function(report_id,
                                   subject_count,
                                   ae_subject_count,
                                   ae_count,
                                   term_summary,
                                   body_system_summary,
                                   gaps) {
  paste(
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "<meta charset=\"utf-8\">",
    paste0("<title>", html_escape(report_id), "</title>"),
    "<style>body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;line-height:1.45;margin:2rem;max-width:960px}table{border-collapse:collapse;width:100%;margin-bottom:1.5rem}th,td{border:1px solid #ddd;padding:.45rem;text-align:left}th{background:#f6f8fa}.metric{display:inline-block;margin-right:1rem;padding:.75rem 1rem;background:#f6f8fa;border-radius:.4rem}.gap{color:#6a4b00}</style>",
    "</head>",
    "<body>",
    paste0("<h1>", html_escape(report_id), "</h1>"),
    "<p>This static AE Explorer example validates mapped AE inputs and summarizes adverse events by preferred term and body system.</p>",
    "<section>",
    "<h2>Overview</h2>",
    paste0("<div class=\"metric\"><strong>Subjects:</strong> ", subject_count, "</div>"),
    paste0("<div class=\"metric\"><strong>Subjects with AEs:</strong> ", ae_subject_count, "</div>"),
    paste0("<div class=\"metric\"><strong>AE records:</strong> ", ae_count, "</div>"),
    "</section>",
    "<section>",
    "<h2>Preferred terms</h2>",
    html_table(term_summary, c("Preferred term", "AE records")),
    "</section>",
    "<section>",
    "<h2>Body systems</h2>",
    html_table(body_system_summary, c("Body system", "AE records")),
    "</section>",
    "<section>",
    "<h2>Known mapping gaps</h2>",
    html_list(gaps, class = "gap"),
    "</section>",
    "</body>",
    "</html>",
    sep = "\n"
  )
}

html_table <- function(df, headers) {
  rows <- apply(df, 1, function(row) {
    paste0("<tr><td>", html_escape(row[[1]]), "</td><td>", html_escape(row[[2]]), "</td></tr>")
  })
  paste(
    "<table>",
    paste0("<thead><tr><th>", html_escape(headers[[1]]), "</th><th>", html_escape(headers[[2]]), "</th></tr></thead>"),
    "<tbody>",
    paste(rows, collapse = "\n"),
    "</tbody>",
    "</table>",
    sep = "\n"
  )
}

html_list <- function(x, class = NULL) {
  if (length(x) == 0) {
    return("<p>None.</p>")
  }
  class_attr <- if (is.null(class)) "" else paste0(" class=\"", html_escape(class), "\"")
  items <- paste0(
    "<li>",
    html_escape(names(x)),
    ifelse(nzchar(names(x)), ": ", ""),
    html_escape(unname(x)),
    "</li>"
  )
  paste0("<ul", class_attr, ">\n", paste(items, collapse = "\n"), "\n</ul>")
}

html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
