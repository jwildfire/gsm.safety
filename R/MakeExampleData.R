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
  if (!("aeseq" %in% names(df_ae))) {
    df_ae$aeseq <- seq_len(nrow(df_ae))
  }
  if (!("aestdy" %in% names(df_ae))) {
    df_ae$aestdy <- sample(seq_len(120), nrow(df_ae), replace = TRUE)
  }
  if (!("aeendy" %in% names(df_ae))) {
    df_ae$aeendy <- df_ae$aestdy + sample(0:14, nrow(df_ae), replace = TRUE)
  }
  if (!("aesev" %in% names(df_ae))) {
    df_ae$aesev <- ifelse(
      is.na(df_ae$aetoxgr),
      "UNKNOWN",
      paste0("GRADE ", df_ae$aetoxgr)
    )
  }

  df_dm <- data.frame(
    subjid = as.character(df_subj$subjid),
    sex = as.character(df_subj$sex),
    age = sample(18:85, nrow(df_subj), replace = TRUE),
    race = sample(c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN", "OTHER"), nrow(df_subj), replace = TRUE),
    stringsAsFactors = FALSE
  )

  df_measure <- data.frame(
    measure = c("ALT", "AST", "TB", "ALP", "CREAT"),
    normal_low = c(0, 0, 0, 35, 0.5),
    normal_high = c(40, 40, 1.2, 120, 1.3),
    typical = c(24, 22, 0.7, 75, 0.9),
    stringsAsFactors = FALSE
  )
  df_visit <- data.frame(
    visit = c("Baseline", "Week 4", "Week 8", "Week 12"),
    visitn = c(0L, 4L, 8L, 12L),
    studyday = c(1L, 29L, 57L, 85L),
    stringsAsFactors = FALSE
  )
  df_lb <- merge(
    merge(
      data.frame(subjid = df_dm$subjid, stringsAsFactors = FALSE),
      df_visit,
      all = TRUE
    ),
    df_measure,
    all = TRUE
  )
  df_lb <- merge(df_lb, df_dm[c("subjid", "sex")], by = "subjid", all.x = TRUE)
  df_lb$value <- round(
    pmax(
      df_lb$normal_low,
      stats::rnorm(
        nrow(df_lb),
        mean = df_lb$typical * (1 + df_lb$visitn / 80),
        sd = pmax(df_lb$typical * 0.18, 0.1)
      )
    ),
    2
  )
  df_lb$typical <- NULL


  list(
    Mapped_SUBJ = df_dm,
    Mapped_AE = data.frame(
      subjid = as.character(df_ae$subjid),
      mdrpt_nsv = as.character(df_ae$mdrpt_nsv),
      mdrsoc_nsv = as.character(df_ae$mdrsoc_nsv),
      aeser = as.character(df_ae$aeser),
      aetoxgr = as.integer(df_ae$aetoxgr),
      aerel = as.character(df_ae$aerel),
      aeseq = as.integer(df_ae$aeseq),
      aestdy = as.integer(df_ae$aestdy),
      aeendy = as.integer(df_ae$aeendy),
      aesev = as.character(df_ae$aesev),
      stringsAsFactors = FALSE
    ),
    Mapped_LB = data.frame(
      subjid = as.character(df_lb$subjid),
      visit = as.character(df_lb$visit),
      visitn = as.integer(df_lb$visitn),
      studyday = as.integer(df_lb$studyday),
      measure = as.character(df_lb$measure),
      value = as.numeric(df_lb$value),
      normal_low = as.numeric(df_lb$normal_low),
      normal_high = as.numeric(df_lb$normal_high),
      sex = as.character(df_lb$sex),
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
