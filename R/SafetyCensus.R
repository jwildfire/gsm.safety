#' Study census, exposure and follow-up for a safety overview
#'
#' The denominators a safety reader needs *before* any event count means
#' anything: how many participants there are, how many were randomised, how
#' many were dosed, how much person-time has accrued, and how many of them the
#' study's safety domains actually name.
#'
#' Every figure is **pooled across treatment arms**. A study-team safety view is
#' a blinded view, and FDA guidance treats even coded arms (A/B/C) as unblinded
#' data, so no arm split is produced here.
#'
#' @section This function counts nothing:
#'
#' It runs the census metrics in `inst/workflow/2_metrics/` over the domains it
#' is given, then reads what they published through the census report's own
#' helpers ([Report_CensusFigures()]). Every number it returns is a `Numerator`
#' a metric published, beside the `Denominator` that same metric published.
#'
#' That is the point of the rebuild rather than a detail of it. Until v1.3.0
#' this function did its own arithmetic, and four of the figures it published
#' were wrong — most of all the death count, which matched the text of a
#' discontinuation reason, never read the death domain, and counted
#' participants who were never enrolled. A figure counted in two places can
#' disagree with itself; there is one counting lane now, and it is the metric.
#' What each metric measures, and what it was measured against, is recorded in
#' `inst/qualification/`.
#'
#' @section Absent, empty, and zero are three different answers:
#'
#' A domain that is not supplied, or that a metric could not read, leaves its
#' figure **absent** — `NA`, with a warning naming the domain. A domain with no
#' rows has measured nothing and is also absent. A populated domain that names
#' nobody publishes **zero**, which is a measurement. Only the last of the
#' three is a number, and none of them is allowed to read as another.
#'
#' @section What moved out of this function in v1.3.0:
#'
#' Three things it used to return are not returned any more, because no metric
#' publishes them and computing them here would be the second counting lane
#' this rebuild exists to remove:
#'
#' * **Median days on treatment** — wants an averaging step in the metric
#'   layer; see [gsm.safety#61](https://github.com/jwildfire/gsm.safety/issues/61).
#' * **Visit-level data coverage** — the thirteenth census figure, carried to
#'   [#58](https://github.com/jwildfire/gsm.safety/issues/58): `gsm.mapping`'s
#'   lab domain carries no visit column under the standard mapping. `Coverage`
#'   is returned with its columns and no rows.
#' * **Disposition states with no metric** — `Ongoing`, the
#'   `Discontinued - <reason>` breakdown built from free text, and
#'   `Not in the disposition domain`, which was a subtraction. `Disposition`
#'   now holds the states the disposition metrics publish: completed,
#'   discontinued and died.
#'
#' @param dfSubjects `data.frame` Mapped subject-level domain, the enrolled
#'   population — `gsm.mapping`'s `Mapped_SUBJ`. It is both the anchor and the
#'   denominator of every other figure.
#' @param dfLabs `data.frame` or `NULL` Mapped lab domain (`Mapped_LB`).
#' @param dfECG `data.frame` or `NULL` Mapped ECG domain (`Mapped_EG`).
#' @param dfAE `data.frame` or `NULL` Mapped adverse-event domain
#'   (`Mapped_AE`).
#' @param dfDisposition `data.frame` or `NULL` Mapped study-completion domain
#'   (`Mapped_STUDCOMP`).
#' @param strIDCol `character` Participant ID column, shared by every domain.
#'   Default: `"subjid"`. A domain keyed on another name is renamed to the
#'   mapped-domain convention before the metrics read it.
#' @param strArmCol,strTimeOnStudyCol,strTimeOnTreatmentCol,strLabVisitCol,strLabVisitNumCol,strECGVisitCol,strECGVisitNumCol,strCompleteCol,strReasonCol,chrDeathValues
#'   **Deprecated and ignored.** Every census metric declares the columns it
#'   reads in its own definition, so this function no longer takes a column
#'   name from its caller. Supplying one warns and changes nothing; they are
#'   kept so that existing calls keep working (D0023.5, approved).
#' @param dfDeath `data.frame` or `NULL` Mapped death domain (`Mapped_Death`) —
#'   `gsm.mapping`'s union of the death domain and the study-completion
#'   domain's discontinuation reason. Without it the death count is absent
#'   rather than read from a reason column, which is how it was wrong before.
#' @param dfRandomization `data.frame` or `NULL` Mapped randomisation domain
#'   (`Mapped_Randomization`). Counting that a participant was randomised
#'   without reading what they were randomised to is what keeps this figure out
#'   of the treatment-arm column.
#' @param strGroupCol `character` Study identifier column in `dfSubjects`,
#'   which groups the metrics. Default: `"studyid"`. It does not appear in what
#'   this function returns, so a subject domain without one still counts, with
#'   a warning.
#'
#' @return `list` with three data.frames, the shape it has always returned:
#'   * `Census` — one row per named figure (`Label`, `Value`, `Denominator`,
#'     `Group`), grouped as `Census`, `Exposure` and `Follow-up`;
#'   * `Coverage` — `Domain`, `Visit`, `VisitNum`, `Participants`, `Expected`;
#'     no rows until the coverage metric lands (#58);
#'   * `Disposition` — one row per published disposition state (`State`,
#'     `Participants`), largest first.
#'
#' @examples
#' dfSubjects <- data.frame(
#'   subjid = c("S1", "S2", "S3"),
#'   studyid = "AA-AA-000-0000",
#'   firstdosedate = as.Date(c("2020-01-01", "2020-01-02", NA)),
#'   timeonstudy = c(120L, 90L, 30L),
#'   timeontreatment = c(110L, 80L, 0L)
#' )
#' dfDeath <- data.frame(subjid = "S2", death = TRUE)
#'
#' suppressWarnings(SafetyCensus(dfSubjects, dfDeath = dfDeath)$Census)
#'
#' @export
SafetyCensus <- function(
    dfSubjects,
    dfLabs = NULL,
    dfECG = NULL,
    dfAE = NULL,
    dfDisposition = NULL,
    strIDCol = "subjid",
    strArmCol = "arm",
    strTimeOnStudyCol = "timeonstudy",
    strTimeOnTreatmentCol = "timeontreatment",
    strLabVisitCol = "visnam",
    strLabVisitNumCol = "visnum",
    strECGVisitCol = "visnam",
    strECGVisitNumCol = "visnum",
    strCompleteCol = "compyn",
    strReasonCol = "compreas",
    chrDeathValues = c("DEATH", "DIED"),
    dfDeath = NULL,
    dfRandomization = NULL,
    strGroupCol = "studyid") {
  .RequireFrame(dfSubjects, "dfSubjects")
  .RequireColumns(dfSubjects, strIDCol, "dfSubjects")

  .WarnDeprecatedCensusArgs(c(
    strArmCol = !missing(strArmCol),
    strTimeOnStudyCol = !missing(strTimeOnStudyCol),
    strTimeOnTreatmentCol = !missing(strTimeOnTreatmentCol),
    strLabVisitCol = !missing(strLabVisitCol),
    strLabVisitNumCol = !missing(strLabVisitNumCol),
    strECGVisitCol = !missing(strECGVisitCol),
    strECGVisitNumCol = !missing(strECGVisitNumCol),
    strCompleteCol = !missing(strCompleteCol),
    strReasonCol = !missing(strReasonCol),
    chrDeathValues = !missing(chrDeathValues)
  ))

  lDomains <- .CensusDomains(
    list(
      Mapped_SUBJ = dfSubjects,
      Mapped_LB = dfLabs,
      Mapped_EG = dfECG,
      Mapped_AE = dfAE,
      Mapped_STUDCOMP = dfDisposition,
      Mapped_Death = dfDeath,
      Mapped_Randomization = dfRandomization
    ),
    strIDCol = strIDCol,
    strGroupCol = strGroupCol
  )

  lWorkflows <- .CensusMetricWorkflows()
  dfFigures <- Report_CensusFigures(
    dfResults = .CensusMetricResults(lWorkflows, lDomains),
    dfMetrics = .CensusMetricDefinitions(lWorkflows),
    lSettings = .CensusReportSettings()
  )

  list(
    Census = .LegacyCensus(dfFigures),
    Coverage = .LegacyCoverage(),
    Disposition = .LegacyDisposition(dfFigures)
  )
}

# ---- what this function returns, declared rather than decided ---------------
#
# The three tables below are the whole of this function's opinion. Everything
# else it does is running the metrics and reading them, so a figure that is
# wrong is wrong in exactly one place: its metric.

#' The census metrics `SafetyCensus()` runs
#'
#' One list, written out rather than derived, so it cannot contain the same
#' metric twice. `tests/testthat/test-SafetyCensus.R` asserts that it is the
#' same set the census report's own settings name — a metric added to the page
#' and not here would be a figure the report shows and the payload lacks.
#'
#' @keywords internal
.CENSUS_METRIC_IDS <- c(
  "saf0004", "saf0005", "saf0006", "saf0007", "saf0008", "saf0009",
  "saf0010", "saf0011", "saf0012", "saf0013", "saf0014", "saf0015"
)

#' The `Census` table: which metric each named figure reads, and where it sits
#'
#' The labels are a contract (D0023.5, approved). The safety overview picks
#' `Enrolled participants`, `Received study drug`, `Person-years on treatment`
#' and `Deaths` out of this payload by exact string and drops a tile silently
#' if one is reworded, so the labels stay word for word and a test says so.
#'
#' `Denominator` is whether the figure is published beside one *here*. Every
#' metric publishes a denominator, and the report shows it in a column headed
#' with what it counts; this payload has no such column, and its reader turns
#' any denominator into a percentage. "73.2 person-years of 762 (10%)" is what
#' carrying it through would produce, so the figures with no percentage to
#' state carry no denominator, exactly as before.
#'
#' @keywords internal
.CENSUS_LEGACY_FIGURES <- data.frame(
  ID = c(
    "saf0005", "saf0006", "saf0007", "saf0004", "saf0008", "saf0009",
    "saf0010", "saf0011", "saf0012", "saf0013"
  ),
  Label = c(
    "Enrolled participants",
    "Randomised to an arm",
    "Received study drug",
    "Deaths",
    "Person-years on study",
    "Person-years on treatment",
    "Participants with a lab result",
    "Participants with an ECG",
    "Participants with a reported AE",
    "Participants with a disposition record"
  ),
  Group = c(
    "Census", "Census", "Census", "Census", "Exposure", "Exposure",
    "Follow-up", "Follow-up", "Follow-up", "Follow-up"
  ),
  Denominator = c(
    FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE
  ),
  stringsAsFactors = FALSE
)

#' The `Disposition` table: the states a metric publishes
#'
#' Three states, because three metrics. `Ongoing` and the
#' `Discontinued - <reason>` breakdown were read out of a free-text reason
#' column, and `Not in the disposition domain` was a subtraction; none of them
#' is a published figure, so none of them is here.
#'
#' @keywords internal
.CENSUS_LEGACY_STATES <- data.frame(
  ID = c("saf0014", "saf0015", "saf0004"),
  State = c("Completed", "Discontinued", "Died"),
  stringsAsFactors = FALSE
)

# ---- the deprecated arguments ------------------------------------------------

#' Warn once, naming every deprecated argument the caller supplied
#'
#' Deprecated and ignored, not removed (D0023.5, approved): the release changes
#' what the numbers say and nothing about how they are read, so a call that
#' passed one of these still runs.
#'
#' @param bSupplied Named `logical` — one element per deprecated argument,
#'   `TRUE` where the caller supplied it.
#'
#' @return `NULL`, invisibly. Called for the warning.
#'
#' @keywords internal
.WarnDeprecatedCensusArgs <- function(bSupplied) {
  chrNamed <- names(bSupplied)[bSupplied]
  if (length(chrNamed) == 0) {
    return(invisible(NULL))
  }
  gsm.core::LogMessage(
    level = "warn",
    message = paste0(
      "Deprecated and ignored: ", paste(chrNamed, collapse = ", "),
      ". The census figures are published by the census metrics in ",
      "inst/workflow/2_metrics/, and every one of them declares the columns ",
      "it reads, so this function no longer takes a column name from its ",
      "caller. These arguments are kept so that existing calls keep working."
    )
  )
  invisible(NULL)
}

# ---- the domains the metrics read --------------------------------------------

#' The mapped domains, keyed the way the metric definitions declare them
#'
#' @param lDomains Named `list` of the domains as they arrived, `NULL` where
#'   the caller supplied none.
#' @param strIDCol `character` Participant ID column the caller keys on.
#' @param strGroupCol `character` Study identifier column in `Mapped_SUBJ`.
#'
#' @return Named `list` of the supplied domains only.
#'
#' @keywords internal
.CensusDomains <- function(lDomains, strIDCol, strGroupCol) {
  for (strDomain in names(lDomains)) {
    if (is.null(lDomains[[strDomain]])) {
      next
    }
    .RequireFrame(lDomains[[strDomain]], strDomain)
    lDomains[[strDomain]] <- .RenameColumn(
      lDomains[[strDomain]], strIDCol, "subjid"
    )
  }

  dfSubjects <- .RenameColumn(lDomains$Mapped_SUBJ, strGroupCol, "studyid")
  if (!("studyid" %in% names(dfSubjects))) {
    # Not an error. The study identifier groups the metrics and is dropped
    # before anything is returned, so refusing to count without one would
    # break a caller over a value this function does not publish.
    gsm.core::LogMessage(
      level = "warn",
      message = paste0(
        "dfSubjects carries no '", strGroupCol, "' column, so every ",
        "participant is counted as one unnamed study. The study identifier ",
        "groups the census metrics and does not appear in what this function ",
        "returns; name it with strGroupCol to have it read."
      )
    )
    dfSubjects[["studyid"]] <- rep("(unnamed study)", nrow(dfSubjects))
  }
  lDomains$Mapped_SUBJ <- dfSubjects

  lDomains[!vapply(lDomains, is.null, logical(1))]
}

#' Rename one column, dropping whatever already held the target name
#'
#' @param df `data.frame` to rename in.
#' @param strFrom,strTo `character` Column names.
#'
#' @return `df`, with `strFrom` renamed to `strTo` where it was present.
#'
#' @keywords internal
.RenameColumn <- function(df, strFrom, strTo) {
  if (identical(strFrom, strTo) || !(strFrom %in% names(df))) {
    return(df)
  }
  # The caller said which column keys this domain; a column already carrying
  # the target name would silently win the rename otherwise.
  df[[strTo]] <- NULL
  names(df)[names(df) == strFrom] <- strTo
  df
}

# ---- running the metrics -----------------------------------------------------

#' Every census metric definition the package ships
#'
#' @return Named `list` of workflows, one per ID in [.CENSUS_METRIC_IDS].
#'
#' @keywords internal
.CensusMetricWorkflows <- function() {
  lWorkflows <- lapply(.CENSUS_METRIC_IDS, function(strID) {
    strPath <- system.file(
      "workflow", "2_metrics", paste0(strID, ".yaml"),
      package = "gsm.safety"
    )
    gsm.core::stop_if(
      cnd = !nzchar(strPath),
      message = paste0(
        "gsm.safety ships no definition for census metric '", strID, "'"
      )
    )
    yaml::read_yaml(strPath)
  })
  names(lWorkflows) <- .CENSUS_METRIC_IDS
  lWorkflows
}

#' Run every census metric the supplied domains can support
#'
#' A metric whose declared domains are not all here is not run, and a metric
#' that stops on what it was given is reported rather than swallowed. Both
#' leave the figure absent, which is what the caller sees; neither leaves a
#' zero, and neither happens quietly.
#'
#' @param lWorkflows Named `list` of metric definitions.
#' @param lDomains Named `list` of the mapped domains.
#'
#' @return `data.frame` of the published rows, with a `MetricID` column, in the
#'   shape `Report_CensusFigures()` reads.
#'
#' @keywords internal
.CensusMetricResults <- function(lWorkflows, lDomains) {
  bRunnable <- vapply(lWorkflows, function(lWorkflow) {
    all(names(lWorkflow$spec) %in% names(lDomains))
  }, logical(1))

  if (any(!bRunnable)) {
    gsm.core::LogMessage(
      level = "warn",
      message = paste0(
        "No domain was supplied for ",
        paste(
          vapply(lWorkflows[!bRunnable], function(lWorkflow) {
            chrSpec <- names(lWorkflow$spec)
            paste0(
              as.character(lWorkflow$meta$Metric), " (",
              paste(chrSpec[!(chrSpec %in% names(lDomains))], collapse = ", "),
              ")"
            )
          }, character(1)),
          collapse = "; "
        ),
        ". Those figures are absent rather than zero."
      )
    )
  }

  lPublished <- lapply(
    lWorkflows[bRunnable], .CensusRunMetric,
    lDomains = lDomains
  )
  lPublished <- lPublished[!vapply(lPublished, is.null, logical(1))]
  if (length(lPublished) == 0) {
    return(.CensusNoResults())
  }

  dfResults <- do.call(rbind, lapply(lPublished, as.data.frame))
  rownames(dfResults) <- NULL
  dfResults
}

#' One metric, run and keyed to the reporting model
#'
#' @param lWorkflow `list` One metric definition.
#' @param lDomains Named `list` of the mapped domains.
#'
#' @return `data.frame` of the rows it published, or `NULL`.
#'
#' @keywords internal
.CensusRunMetric <- function(lWorkflow, lDomains) {
  strID <- as.character(lWorkflow$meta$ID)
  dfSummary <- tryCatch(
    gsm.core::RunWorkflow(lWorkflow, lData = lDomains)$Analysis_Summary,
    error = function(e) {
      gsm.core::LogMessage(
        level = "warn",
        message = paste0(
          "'", strID, "' (", as.character(lWorkflow$meta$Metric),
          ") stopped on this study, so its figure is absent rather than ",
          "zero: ", conditionMessage(e)
        )
      )
      NULL
    }
  )
  if (!is.data.frame(dfSummary) || nrow(dfSummary) == 0) {
    return(NULL)
  }
  dfSummary$MetricID <- rep(paste0("Analysis_", strID), nrow(dfSummary))
  dfSummary
}

#' What a study whose metrics all published nothing produces
#'
#' @return `data.frame` with the reporting-model columns and no rows.
#'
#' @keywords internal
.CensusNoResults <- function() {
  data.frame(
    MetricID = character(0), GroupID = character(0), GroupLevel = character(0),
    Numerator = numeric(0), Denominator = numeric(0), Metric = numeric(0),
    Score = numeric(0), Flag = numeric(0), stringsAsFactors = FALSE
  )
}

#' The metric definitions, in the shape the reporting model carries them
#'
#' `gsm.reporting::MakeMetric()` builds this from the same yaml in a full
#' pipeline. It is rebuilt here rather than depended on: gsm.reporting is a
#' suggested package, and this function has to work for a caller who has one
#' study's domains and no reporting model.
#'
#' @param lWorkflows Named `list` of metric definitions.
#'
#' @return `data.frame` with `ID`, `MetricID`, `Metric`, `Numerator` and
#'   `Denominator`.
#'
#' @keywords internal
.CensusMetricDefinitions <- function(lWorkflows) {
  dfMetrics <- do.call(rbind, lapply(lWorkflows, function(lWorkflow) {
    lMeta <- lWorkflow$meta
    data.frame(
      ID = as.character(lMeta$ID),
      MetricID = paste0("Analysis_", as.character(lMeta$ID)),
      Metric = as.character(lMeta$Metric),
      Numerator = as.character(lMeta$Numerator),
      Denominator = as.character(lMeta$Denominator),
      stringsAsFactors = FALSE
    )
  }))
  rownames(dfMetrics) <- NULL
  dfMetrics
}

#' The census report's own settings
#'
#' Read from `inst/workflow/4_modules/safety_census.yaml`, so the sections, the
#' person-time metrics and the days-per-year the page presents are the ones
#' this payload presents. Two readers of the same figures cannot disagree about
#' which of them are published in days.
#'
#' @return `list` of settings.
#'
#' @keywords internal
.CensusReportSettings <- function() {
  strPath <- system.file(
    "workflow", "4_modules", "safety_census.yaml",
    package = "gsm.safety"
  )
  gsm.core::stop_if(
    cnd = !nzchar(strPath),
    message = "gsm.safety ships no census report definition"
  )
  yaml::read_yaml(strPath)$meta$lSettings
}

# ---- reading the figures out -------------------------------------------------

#' One presented figure, or `NA` where the metric published none
#'
#' @param dfFigures `data.frame` From [Report_CensusFigures()].
#' @param strID `character` A metric's short ID.
#' @param strCol `character` Column to read.
#'
#' @return `numeric(1)`.
#'
#' @keywords internal
.CensusFigureValue <- function(dfFigures, strID, strCol) {
  dfRow <- dfFigures[dfFigures$ID == strID, , drop = FALSE]
  if (nrow(dfRow) == 0) {
    return(NA_real_)
  }
  as.numeric(dfRow[[strCol]][1])
}

#' The `Census` table
#'
#' @param dfFigures `data.frame` From [Report_CensusFigures()].
#'
#' @return `data.frame` with `Label`, `Value`, `Denominator` and `Group`.
#'
#' @keywords internal
.LegacyCensus <- function(dfFigures) {
  dfLegacy <- .CENSUS_LEGACY_FIGURES
  data.frame(
    Label = dfLegacy$Label,
    Value = vapply(
      dfLegacy$ID,
      function(strID) .CensusFigureValue(dfFigures, strID, "Value"),
      numeric(1), USE.NAMES = FALSE
    ),
    Denominator = vapply(
      seq_len(nrow(dfLegacy)),
      function(i) {
        if (!dfLegacy$Denominator[i]) {
          return(NA_real_)
        }
        .CensusFigureValue(dfFigures, dfLegacy$ID[i], "Denominator")
      },
      numeric(1)
    ),
    Group = dfLegacy$Group,
    stringsAsFactors = FALSE
  )
}

#' The `Coverage` table
#'
#' Its columns, and no rows, until the coverage metric lands
#' ([#58](https://github.com/jwildfire/gsm.safety/issues/58)). Counting it here
#' from a raw domain is what this rebuild removed; an empty table is what the
#' reader is told, and its reader already says so in words.
#'
#' @return `data.frame` with the coverage columns and no rows.
#'
#' @keywords internal
.LegacyCoverage <- function() {
  data.frame(
    Domain = character(0), Visit = character(0), VisitNum = numeric(0),
    Participants = numeric(0), Expected = numeric(0),
    stringsAsFactors = FALSE
  )
}

#' The `Disposition` table
#'
#' @param dfFigures `data.frame` From [Report_CensusFigures()].
#'
#' @return `data.frame` with `State` and `Participants`, largest first.
#'
#' @keywords internal
.LegacyDisposition <- function(dfFigures) {
  dfStates <- .CENSUS_LEGACY_STATES
  nParticipants <- vapply(
    dfStates$ID,
    function(strID) .CensusFigureValue(dfFigures, strID, "Value"),
    numeric(1), USE.NAMES = FALSE
  )
  bPublished <- !is.na(nParticipants)

  dfDisposition <- data.frame(
    State = dfStates$State[bPublished],
    Participants = nParticipants[bPublished],
    stringsAsFactors = FALSE
  )
  dfDisposition <- dfDisposition[
    order(dfDisposition$Participants, decreasing = TRUE), ,
    drop = FALSE
  ]
  rownames(dfDisposition) <- NULL
  dfDisposition
}
