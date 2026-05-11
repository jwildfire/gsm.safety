#' Default GSM-to-SafetyGraphics table map
#'
#' `sg_default_table_map()` identifies the GSM mapped `lData` tables that are
#' used as SafetyGraphics domains. The initial contract is intentionally small
#' and favors existing `gsm.mapping` fields over derived or renamed fields.
#'
#' @return A named character vector where names are SafetyGraphics domains and
#'   values are expected GSM `lData` table names.
#' @export
sg_default_table_map <- function() {
  c(
    dm = "Mapped_SUBJ",
    aes = "Mapped_AE",
    labs = "Mapped_LB"
  )
}

#' Default GSM-to-SafetyGraphics field mapping
#'
#' The mapping uses current field names from `gsm.mapping` wherever possible.
#' Missing values are explicit gaps that should not be silently invented by
#' `gsm.safety` without a documented adapter decision.
#'
#' @return A nested list suitable for SafetyGraphics custom mapping inputs.
#' @export
sg_default_mapping <- function() {
  list(
    dm = list(
      id_col = "subjid",
      treatment_col = NULL,
      age_col = "agerep",
      sex_col = "sex",
      race_col = "race"
    ),
    aes = list(
      id_col = "subjid",
      term_col = "mdrpt_nsv",
      bodsys_col = "mdrsoc_nsv",
      serious_col = "aeser",
      start_date_col = "aest_dt",
      end_date_col = "aeen_dt",
      grade_col = "aetoxgr",
      ongoing_col = "aeongo",
      related_col = "aerel"
    ),
    labs = list(
      id_col = "subjid",
      measure_col = "toxgrg_nsv",
      date_col = "lb_dt",
      visit_col = NULL,
      visitn_col = NULL,
      studyday_col = NULL,
      value_col = NULL,
      normal_col_low = NULL,
      normal_col_high = NULL
    )
  )
}

#' GSM-to-SafetyGraphics field contract
#'
#' @return A data frame describing domain tables, SafetyGraphics mapping keys,
#'   GSM fields, requirement levels, and notes.
#' @export
sg_field_contract <- function() {
  data.frame(
    domain = c(
      rep("dm", 5),
      rep("aes", 9),
      rep("labs", 9)
    ),
    table = c(
      rep("Mapped_SUBJ", 5),
      rep("Mapped_AE", 9),
      rep("Mapped_LB", 9)
    ),
    safety_key = c(
      "id_col", "treatment_col", "age_col", "sex_col", "race_col",
      "id_col", "term_col", "bodsys_col", "serious_col", "start_date_col",
      "end_date_col", "grade_col", "ongoing_col", "related_col",
      "id_col", "measure_col", "date_col", "visit_col", "visitn_col",
      "studyday_col", "value_col", "normal_col_low", "normal_col_high"
    ),
    gsm_field = c(
      "subjid", NA, "agerep", "sex", "race",
      "subjid", "mdrpt_nsv", "mdrsoc_nsv", "aeser", "aest_dt",
      "aeen_dt", "aetoxgr", "aeongo", "aerel",
      "subjid", "toxgrg_nsv", "lb_dt", NA, NA, NA, NA, NA, NA
    ),
    requirement = c(
      "required", "optional_gap", "optional", "optional", "optional",
      "required", "required", "required", "optional", "optional",
      "optional", "optional", "optional", "optional",
      "required_if_labs", "required_if_labs", "optional", "chart_gap", "chart_gap",
      "chart_gap", "chart_gap", "chart_gap", "chart_gap"
    ),
    source = c(
      "gsm.mapping SUBJ", "not currently in gsm.mapping SUBJ", "gsm.mapping SUBJ",
      "gsm.mapping SUBJ", "gsm.mapping SUBJ",
      "gsm.mapping AE", "gsm.mapping AE", "gsm.mapping AE", "gsm.mapping AE",
      "gsm.mapping AE", "gsm.mapping AE", "gsm.mapping AE", "gsm.mapping AE",
      "gsm.mapping AE", "gsm.mapping LB", "gsm.mapping LB", "gsm.mapping LB",
      "not currently in gsm.mapping LB", "not currently in gsm.mapping LB",
      "not currently in gsm.mapping LB", "not currently in gsm.mapping LB",
      "not currently in gsm.mapping LB", "not currently in gsm.mapping LB"
    ),
    notes = c(
      "Primary subject identifier used to join domains.",
      "Current SUBJ mapping has no treatment/arm field; safetyCharts aeExplorer can use a placeholder when missing.",
      "Subject age, available for demographics/outlier charts.",
      "Subject sex, available for demographics/outlier charts.",
      "Subject race, available for demographics/outlier charts.",
      "Subject identifier should match Mapped_SUBJ$subjid.",
      "Preferred term used by AE Explorer term_col.",
      "Body system / SOC used by AE Explorer bodsys_col.",
      "Serious AE flag available for future filters/details.",
      "AE start date available for timelines/details.",
      "AE end date available for timelines/details.",
      "Toxicity grade available for future filters/details.",
      "Ongoing flag available for future filters/details.",
      "Relationship available for future filters/details.",
      "Subject identifier should match Mapped_SUBJ$subjid.",
      "Current LB mapping exposes toxicity grade group text; this may not be enough for quantitative lab charts.",
      "Lab date is available, but SafetyGraphics outlier charts usually expect study day/visit fields.",
      "Needed by safetyOutlierExplorer-style charts; not in current LB mapping.",
      "Needed by safetyOutlierExplorer-style charts; not in current LB mapping.",
      "Needed by safetyOutlierExplorer-style charts; not in current LB mapping.",
      "Needed by quantitative lab charts; not in current LB mapping.",
      "Needed by quantitative lab charts; not in current LB mapping.",
      "Needed by quantitative lab charts; not in current LB mapping."
    ),
    stringsAsFactors = FALSE
  )
}

#' Build SafetyGraphics domain data from GSM lData
#'
#' This is a pass-through adapter: it selects available mapped GSM tables and
#' exposes them under SafetyGraphics domain names without renaming columns.
#'
#' @param lData Named list of GSM workflow data frames.
#' @param table_map Named character vector from SafetyGraphics domains to GSM
#'   table names. Defaults to [sg_default_table_map()].
#' @param include_optional Logical. If `TRUE`, include optional domains such as
#'   `labs` when present. If `FALSE`, only `dm` and `aes` are returned.
#'
#' @return A named list of data frames keyed by SafetyGraphics domain name.
#' @export
sg_domain_data <- function(lData, table_map = sg_default_table_map(), include_optional = TRUE) {
  if (!is.list(lData)) {
    stop("`lData` must be a named list of data frames.", call. = FALSE)
  }

  domains <- names(table_map)
  if (!include_optional) {
    domains <- setdiff(domains, "labs")
  }

  out <- list()
  for (domain in domains) {
    table <- unname(table_map[[domain]])
    if (!table %in% names(lData)) {
      if (identical(domain, "labs")) {
        next
      }
      stop(
        sprintf("Missing required lData table `%s` for SafetyGraphics domain `%s`.", table, domain),
        call. = FALSE
      )
    }
    if (!is.data.frame(lData[[table]])) {
      stop(sprintf("`lData$%s` must be a data frame.", table), call. = FALSE)
    }
    out[[domain]] <- lData[[table]]
  }

  out
}

#' Validate the initial GSM-to-SafetyGraphics data contract
#'
#' @param lData Named list of GSM workflow data frames.
#' @param include_optional Logical. If `TRUE`, validate `Mapped_LB` when present.
#'
#' @return Invisibly returns `TRUE` when validation succeeds.
#' @export
sg_validate_data_contract <- function(lData, include_optional = TRUE) {
  domain_data <- sg_domain_data(lData, include_optional = include_optional)
  contract <- sg_field_contract()
  required <- contract[contract$requirement %in% c("required", "required_if_labs"), , drop = FALSE]

  if (!include_optional || !"labs" %in% names(domain_data)) {
    required <- required[required$domain != "labs", , drop = FALSE]
  }

  missing_columns <- character()
  for (i in seq_len(nrow(required))) {
    row <- required[i, ]
    table <- row$table
    field <- row$gsm_field
    domain <- row$domain
    if (is.na(field)) {
      next
    }
    if (!field %in% names(lData[[table]])) {
      missing_columns <- c(
        missing_columns,
        sprintf("%s.%s for `%s`", table, field, domain)
      )
    }
  }

  if (length(missing_columns) > 0) {
    stop(
      paste0(
        "Missing required GSM-to-SafetyGraphics columns: ",
        paste(missing_columns, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
