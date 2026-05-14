#' Create example data for safety renderers with gsm.datasim
#'
#' @param nSubjects Number of synthetic subjects to generate.
#' @param nSites Number of synthetic sites to generate.
#' @param nAe Number of synthetic adverse event records to generate.
#' @param seed Random seed used to keep examples deterministic.
#'
#' @return A named list containing mapped example data domains.
#' @export
MakeExampleData <- function(nSubjects = 12,
                            nSites = 3,
                            nAe = 24,
                            seed = 1) {
  if (!requireNamespace("gsm.datasim", quietly = TRUE)) {
    stop(
      "Package 'gsm.datasim' is required to generate example data.",
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
    study_id = "GSM-SAFETY-EXAMPLE",
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
  raw_data <- find_example_raw_data(generated_data, c("Raw_SUBJ", "Raw_AE"))

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

find_example_raw_data <- function(x, required_domains) {
  if (is.list(x) && all(required_domains %in% names(x))) {
    return(x)
  }
  if (!is.list(x)) {
    return(NULL)
  }

  for (item in rev(x)) {
    result <- find_example_raw_data(item, required_domains)
    if (!is.null(result)) {
      return(result)
    }
  }

  NULL
}
