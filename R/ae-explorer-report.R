#' Save an initialized AE Explorer widget as standalone HTML
#'
#' @param lInitialized A list returned by [safetyCharts::init_aeExplorer()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when absent.
#'
#' @return A list with the report path and htmlwidget.
#' @export
RenderAeExplorerWidget <- function(lInitialized,
                                   strOutputDir = getwd(),
                                   strOutputFile = "ae_explorer") {
  if (!dir.exists(strOutputDir)) {
    dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }
  strOutputPath <- file.path(strOutputDir, strOutputFile)

  widget <- safetyCharts::render_widget(
    "aeExplorer",
    lInitialized$data,
    lInitialized$settings
  )
  htmlwidgets::saveWidget(widget, file = strOutputPath, selfcontained = TRUE)

  list(
    path = normalizePath(strOutputPath, winslash = "/", mustWork = FALSE),
    widget = widget,
    initialized = lInitialized
  )
}

#' Create AE Explorer report settings from a workr spec
#'
#' @param lSpec A `workr` workflow spec for the AE Explorer report.
#'
#' @return A list of domain mappings, widget settings, and known gaps for AE Explorer.
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
        treatment_col = "sex"
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
      aeout = "No current Mapped_AE outcome field identified."
    )
  )
}

#' Render an interactive AE Explorer report
#'
#' This report artifact validates mapped AE inputs, initializes AE Explorer
#' settings with [safetyCharts::init_aeExplorer()], renders the interactive
#' widget with [safetyCharts::render_widget()], and writes a standalone HTML
#' file that can be attached to a workflow run or shown in pkgdown examples.
#'
#' @param lData A named list containing `Mapped_SUBJ` and `Mapped_AE` data frames.
#' @param lSettings AE Explorer settings from [MakeAeExplorerSettings()].
#' @param strOutputDir Directory where the HTML report should be written.
#' @param strOutputFile Output file stem or filename. `.html` is appended when
#'   absent.
#'
#' @return A list with the report path, htmlwidget, and summary tables.
#' @export
Report_AE_Explorer <- function(lData,
                               lSettings,
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

  if (!grepl("[.]html?$", strOutputFile, ignore.case = TRUE)) {
    strOutputFile <- paste0(strOutputFile, ".html")
  }

  initialized <- safetyCharts::init_aeExplorer(
    data = list(
      dm = df_dm,
      aes = df_ae
    ),
    settings = lSettings$settings
  )
  report <- RenderAeExplorerWidget(
    lInitialized = initialized,
    strOutputDir = strOutputDir,
    strOutputFile = strOutputFile
  )

  c(
    report,
    list(
      summaries = list(
        terms = term_summary,
        body_systems = body_system_summary
      )
    )
  )
}

#' Create example data for the AE Explorer report with gsm.datasim
#'
#' @param nSubjects Number of synthetic subjects to generate.
#' @param nSites Number of synthetic sites to generate.
#' @param nAe Number of synthetic adverse event records to generate.
#' @param seed Random seed used to keep examples deterministic.
#'
#' @return A named list containing `Mapped_SUBJ` and `Mapped_AE` example data.
#' @export
MakeAeExplorerExampleData <- function(nSubjects = 12,
                                      nSites = 3,
                                      nAe = 24,
                                      seed = 1) {
  if (!requireNamespace("gsm.datasim", quietly = TRUE)) {
    stop(
      "Package 'gsm.datasim' is required to generate AE Explorer example data.",
      call. = FALSE
    )
  }

  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
  } else {
    on.exit(rm(".Random.seed", envir = .GlobalEnv), add = TRUE)
  }
  set.seed(seed)

  config <- gsm.datasim::create_study_config(
    study_id = "GSM-SAFETY-AE-EXAMPLE",
    participant_count = nSubjects,
    site_count = nSites
  )
  config <- gsm.datasim::set_temporal_config(
    config,
    start_date = "2023-01-01",
    snapshot_count = 1,
    snapshot_width = "months"
  )
  config <- gsm.datasim::add_dataset_config(
    config,
    "Raw_AE",
    enabled = TRUE,
    count_formula = function(config) nAe
  )

  generated_data <- gsm.datasim::generate_study_data(config, verbose = FALSE)
  raw_data <- find_ae_example_raw_data(generated_data)

  if (is.null(raw_data)) {
    stop(
      "gsm.datasim did not generate a snapshot containing Raw_SUBJ and Raw_AE.",
      call. = FALSE
    )
  }

  df_subj <- raw_data$Raw_SUBJ
  df_ae <- raw_data$Raw_AE

  if (!("sex" %in% names(df_subj))) {
    df_subj$sex <- sample(c("F", "M"), nrow(df_subj), replace = TRUE)
  }
  if (!("mdrpt_nsv" %in% names(df_ae))) {
    df_ae$mdrpt_nsv <- "Unspecified adverse event"
  }
  if (!("mdrsoc_nsv" %in% names(df_ae))) {
    df_ae$mdrsoc_nsv <- "Unspecified system organ class"
  }
  if (!("aeser" %in% names(df_ae))) {
    df_ae$aeser <- NA_character_
  }
  if (!("aetoxgr" %in% names(df_ae))) {
    df_ae$aetoxgr <- NA_integer_
  }
  if (!("aerel" %in% names(df_ae))) {
    df_ae$aerel <- NA_character_
  }

  list(
    Mapped_SUBJ = data.frame(
      subjid = as.character(df_subj$subjid),
      sex = as.character(df_subj$sex),
      stringsAsFactors = FALSE
    ),
    Mapped_AE = data.frame(
      subjid = as.character(df_ae$subjid),
      mdrpt_nsv = as.character(df_ae$mdrpt_nsv),
      mdrsoc_nsv = as.character(df_ae$mdrsoc_nsv),
      aeser = as.character(df_ae$aeser),
      aetoxgr = as.integer(df_ae$aetoxgr),
      aerel = as.character(df_ae$aerel),
      stringsAsFactors = FALSE
    )
  )
}

find_ae_example_raw_data <- function(x) {
  if (is.list(x) && all(c("Raw_SUBJ", "Raw_AE") %in% names(x))) {
    return(x)
  }
  if (!is.list(x)) {
    return(NULL)
  }

  for (item in rev(x)) {
    result <- find_ae_example_raw_data(item)
    if (!is.null(result)) {
      return(result)
    }
  }

  NULL
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

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
