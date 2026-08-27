#' Participant Profile Widget
#'
#' A widget that renders the safety.viz participant profile: the shared
#' drill-down that answers "what happened to this person" in one pass — a
#' header carrying the participant's demographics, a labs-over-time spaghetti
#' standardized to multiples of the upper limit of normal or of baseline with
#' reference cutpoints, adverse-event tracks drawn on the same study-day axis,
#' and a measure table with per-measure sparklines that expand into an inset.
#' A cohort of more than one participant is ranked worst-first and stepped
#' through.
#'
#' The profile is already reachable *inside* several widgets: `Widget_HepExplorer()`,
#' `Widget_Histogram()` and `Widget_OutlierExplorer()` mount it in a rail beside
#' the chart, driven by whatever the reviewer selects there. This widget is the
#' standalone surface, for a report that names its cohort up front rather than
#' asking someone to click for it — a per-participant appendix, a narrative for
#' a set of flagged participants, a listing that stands on its own page.
#'
#' Give it a cohort with `chrParticipants`. Without one it renders its controls
#' and waits: the module's standalone mount listens for a `participantsSelected`
#' event, which nothing in a static R report dispatches, so a profile with no
#' cohort is an empty profile.
#'
#' That listener has a useful consequence in a multi-chart document. It listens
#' on `document` by default, and every other safety.viz chart dispatches its
#' selections there, so a profile placed in the same R Markdown page as (say) a
#' histogram or an outlier explorer will follow what the reader selects on that
#' chart, replacing whatever `chrParticipants` opened on. Scope it to one chart
#' with `lSettings$listen_to`, or leave it alone in a page of its own.
#'
#' @param dfResults `data.frame` Long-format lab results, one record per
#'   participant per measure per visit — the same contract
#'   [Widget_HepExplorer()] consumes. Column names are supplied by `lSettings`;
#'   the defaults expect the BDS standard (`USUBJID`/`TEST`/`STRESN`/`STNRHI`,
#'   plus `STNRLO`/`VISIT`/`VISITNUM` — see
#'   `inst/schema/participant-profile.json`).
#' @param chrParticipants `character` Participant ids to profile, in any order
#'   — the module ranks them worst-first and opens on the first. Default:
#'   `NULL`, which renders the waiting state.
#' @param dfAE `data.frame` Adverse events, one record per event, for the AE
#'   tracks beside the labs. Optional; supplying it turns the AE domain on.
#'   Its column mapping is `lSettings$ae`, which deliberately reuses the names
#'   [Widget_AeTimelines()] already takes (`id_col`, `term_col`, `minor_col`,
#'   `major_col`, `stdy_col`, `endy_col`, `color`, `highlight`), so a report
#'   already feeding that widget can feed this one the same mapping. Default:
#'   `NULL`, which draws labs only.
#' @param lSettings `list` safety.viz participant-profile settings overrides;
#'   merged onto the module's `DEFAULT_SETTINGS` client-side, so only overrides
#'   are needed. `measure_values` maps the ALT/AST/TB/ALP keys onto the data's
#'   own measure names, and `details` names the header demographics.
#' @param width `character` Width of the widget as a CSS unit. Default: `NULL`.
#' @param height `character` Height of the widget as a CSS unit. Default:
#'   `NULL`.
#' @param elementId `character` ID of the widget's HTML element. Default:
#'   `NULL`.
#' @param bDebug `logical` Print debug messages in the browser console?
#'   Default: `FALSE`.
#'
#' @examples
#' dfResults <- ExampleData("adbds")
#' dfAE <- ExampleData("adae")
#'
#' # A named cohort, with the adverse-event tracks beside the labs.
#' Widget_ParticipantProfile(
#'   dfResults,
#'   chrParticipants = c("01-701-1015", "01-701-1023", "01-701-1028"),
#'   dfAE = dfAE[nzchar(dfAE$AEDECOD), ],
#'   lSettings = list(
#'     studyday_col = "VISITNUM",
#'     measure_values = list(
#'       ALT = "Alanine Aminotransferase",
#'       AST = "Aspartate Aminotransferase",
#'       TB = "Bilirubin",
#'       ALP = "Alkaline Phosphatase"
#'     ),
#'     details = list(
#'       list(value_col = "ARM", label = "Treatment Group"),
#'       list(value_col = "SEX", label = "Sex"),
#'       list(value_col = "RACE", label = "Race")
#'     )
#'   )
#' )
#'
#' @export
Widget_ParticipantProfile <- function(
    dfResults,
    chrParticipants = NULL,
    dfAE = NULL,
    lSettings = list(),
    width = NULL,
    height = NULL,
    elementId = NULL,
    bDebug = FALSE) {
  x <- BuildWidgetPayload(
    dfResults = dfResults,
    lSettings = lSettings,
    strModule = "participant-profile",
    bDebug = bDebug
  )

  gsm.core::stop_if(
    cnd = !is.null(chrParticipants) && !is.character(chrParticipants),
    message = "chrParticipants is not a character vector"
  )
  x$chrParticipants <- if (is.null(chrParticipants)) {
    character(0)
  } else {
    chrParticipants
  }

  if (!is.null(dfAE)) {
    gsm.core::stop_if(
      cnd = !is.data.frame(dfAE),
      message = "dfAE is not a data.frame"
    )
    CheckAeColumns(dfAE = dfAE, lAeSettings = lSettings$ae)
    x$dfAE <- dfAE
  }

  htmlwidgets::createWidget(
    name = "Widget_ParticipantProfile",
    x = x,
    width = width,
    height = height,
    package = "gsm.safety",
    elementId = elementId,
    sizingPolicy = WidgetSizingPolicy()
  )
}

#' Check the adverse-event mapping against the adverse-event data
#'
#' The AE domain is a second data frame that the participant-profile contract
#' carries in `settings.ae.data` rather than as a dataset of its own, so
#' [BuildWidgetPayload()] never sees it. Its column mapping is checked here
#' instead: an id or onset-day column that does not exist yields an empty
#' timeline client-side, which is indistinguishable from a participant with no
#' events.
#'
#' @param dfAE `data.frame` Adverse events, one record per event.
#' @param lAeSettings `list` The `ae` member of the widget's settings, or
#'   `NULL` for the defaults.
#'
#' @return `NULL`, invisibly. Called for its errors.
#'
#' @noRd
CheckAeColumns <- function(dfAE, lAeSettings = NULL) {
  if (is.null(lAeSettings)) {
    lAeSettings <- list()
  }
  # Mirrors AE_DEFAULT_SETTINGS in safety.viz's participant-profile/ae.js: the
  # two columns without which an event cannot be placed on the timeline.
  lRequired <- list(id_col = "USUBJID", stdy_col = "ASTDY")

  for (strKey in names(lRequired)) {
    strColumn <- lAeSettings[[strKey]]
    if (is.null(strColumn)) {
      strColumn <- lRequired[[strKey]]
    }
    gsm.core::stop_if(
      cnd = !(strColumn %in% names(dfAE)),
      message = paste0(
        "Column '", strColumn, "' (setting 'ae$", strKey,
        "') not found in dfAE"
      )
    )
  }

  invisible(NULL)
}
