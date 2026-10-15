#' FDA abnormality level criteria for laboratory results
#'
#' Appendix Tables 56 and 57 of the FDA *Standard Safety Tables and Figures:
#' Integrated Guide*, version 2.0 (April 2025; CDER BIRRS, MAPP 6025.9),
#' transcribed row for row: the level 1, 2 and 3 abnormality thresholds the
#' guide uses to count "subjects with analyte values exceeding specified
#' levels" (Tables 20 and 52 to 55) when no established grading system such as
#' DAIDS or CTCAE applies. Table 56 (guide section 5.1.1, pages 119 to 120)
#' covers general chemistry, kidney function, liver biochemistry and lipids;
#' Table 57 (section 5.1.2, page 121) covers the complete blood count, the WBC
#' differential and coagulation studies. The guide provides the criteria "for
#' the purpose of identifying outliers"; the individual thresholds do not
#' correspond to specific safety outcomes.
#'
#' One row per printed row: a parameter in one direction, with a qualifier
#' where the guide splits a row by sex or by fasting state. The three levels
#' are cumulative — a level 3 result also meets levels 1 and 2 — and every row
#' compares with one operator. `Basis` says what the threshold is compared
#' against:
#'
#' | `Basis` | The level is | Example |
#' |---|---|---|
#' | `absolute` | a value in `Unit` | Sodium, low: `<132` mEq/L |
#' | `uln_multiple` | a multiple of the upper limit of normal | ALT, high: `>3.0 x ULN` |
#' | `baseline_multiple` | a multiple of the participant's baseline | Creatinine, increase: `>=1.5 x baseline` |
#' | `baseline_percent_decrease` | a percentage decrease from baseline | eGFR, decrease: `>=25% decrease` |
#' | `baseline_change` | an absolute change from baseline in `Unit` | Hemoglobin, decrease: `>1.5 dec. from baseline` |
#'
#' `Derive_AbnormalityLevel()` (gsm.safety#78) applies the `absolute` and `uln_multiple` rows;
#' the baseline-relative bases need a baseline column and are left to the
#' phase 1 engines.
#'
#' Transcription decisions are recorded in the `Note` column beside the row
#' they concern: the hemoglobin level 1 ranges are read as the upper bound
#' because the levels are cumulative, and the platelet row, printed with the
#' unit `x 10^9 cells/uL` beside thresholds of 140,000 and below, is filed in
#' cells per uL so a per-uL count grades.
#' Non-ASCII characters in the guide are written in ASCII (`u` for the micro
#' sign, `>=` for the greater-than-or-equal sign). The build script and the
#' hand-checked CSV are in the repository's `data-raw/` directory.
#'
#' @format A data frame with 46 rows and 18 columns:
#' \describe{
#'   \item{Table}{`integer` Guide table the row comes from: 56 or 57.}
#'   \item{Panel}{`character` Panel heading in the table, e.g. `"Liver Biochemistry"`.}
#'   \item{Parameter}{`character` Laboratory parameter as printed, without the direction.}
#'   \item{Direction}{`character` `"low"`, `"high"`, `"increase"` or `"decrease"`.}
#'   \item{Qualifier}{`character` Sex or fasting-state qualifier the guide attaches to the row, else `NA`.}
#'   \item{Unit}{`character` Unit printed with the parameter.}
#'   \item{Basis}{`character` What the thresholds compare against; see the table above.}
#'   \item{Operator}{`character` Comparison operator shared by the row's levels: `"<"`, `">"` or `">="`.}
#'   \item{Level1, Level2, Level3}{`numeric` Threshold at each level; `NA` where the guide prints N/A.}
#'   \item{Level1Text, Level2Text, Level3Text}{`character` The criterion as printed.}
#'   \item{GuideVersion}{`character` `"2.0"`.}
#'   \item{GuideSection}{`character` `"5.1.1"` for Table 56, `"5.1.2"` for Table 57.}
#'   \item{GuidePage}{`integer` Printed page of the guide the row is on.}
#'   \item{Note}{`character` Transcription note, else `NA`.}
#' }
#' @source FDA CDER, *Standard Safety Tables and Figures: Integrated Guide*,
#'   version 2.0, April 2025, Appendix 5.1,
#'   <https://www.fda.gov/media/187065/download>.
#' @seealso [FDA_ExtremeValues] for the companion extreme-value thresholds,
#'   `Derive_AbnormalityLevel()` (gsm.safety#78) for the grading rule applied to lab data.
#' @examples
#' data(FDA_AbnormalityLevels)
#' subset(
#'   FDA_AbnormalityLevels,
#'   Panel == "Liver Biochemistry",
#'   select = c(Parameter, Direction, Basis, Level1, Level2, Level3)
#' )
"FDA_AbnormalityLevels"

#' FDA extreme laboratory and vital sign values suggestive of error
#'
#' Appendix Tables 58, 59 and 60 of the FDA *Standard Safety Tables and
#' Figures: Integrated Guide*, version 2.0 (April 2025; guide section 5.2,
#' "Extreme Clinical Laboratory and Vital Sign Values, Version 1.0"),
#' transcribed row for row: the thresholds beyond which a result is treated
#' as a likely laboratory or recording error and removed from the guide's mean
#' change from baseline over time figures (Figures 6 and 9). Table 58 (section
#' 5.2.1, pages 122 to 123) covers serum, plasma and whole blood chemistry;
#' Table 59 (section 5.2.2, page 123) hematology; Table 60 (section 5.2.3,
#' page 124) vital signs.
#'
#' The guide prints each parameter once with a US-conventional and an SI
#' column pair. This dataset is long: every parameter appears twice, once per
#' `UnitSystem`, so `Derive_ExtremeValueFlag()` (gsm.safety#78) can join on the unit the data
#' actually carries. Table 60 prints one unit set, so its rows are repeated
#' under both systems, except temperature, which the guide gives in both
#' Fahrenheit (filed as US) and Celsius (filed as SI). A missing `Low` or
#' `High` is an `N/A` in the guide: no threshold in that direction.
#'
#' Transcription decisions are in the `Note` column beside the row they
#' concern. Non-ASCII characters in the guide are written in ASCII (`u` for the
#' micro sign). The build script and the hand-checked CSV are in the
#' repository's `data-raw/` directory.
#'
#' @format A data frame with 80 rows (40 parameters, two unit systems each) and 13 columns:
#' \describe{
#'   \item{Table}{`integer` Guide table the row comes from: 58, 59 or 60.}
#'   \item{Panel}{`character` `"General Chemistry"`, `"Hematology"` or `"Vital Signs"`.}
#'   \item{Parameter}{`character` Parameter as printed, without the specimen.}
#'   \item{Specimen}{`character` Specimen the guide prints in parentheses (`"serum"`, `"plasma"`, `"blood"`, ...), `NA` for vital signs.}
#'   \item{UnitSystem}{`character` `"US"` (US conventional) or `"SI"`.}
#'   \item{Unit}{`character` Unit in that system; `NA` for the unitless INR.}
#'   \item{Low}{`numeric` Values below this are extreme; `NA` when the guide prints N/A.}
#'   \item{High}{`numeric` Values above this are extreme; `NA` when the guide prints N/A.}
#'   \item{References}{`character` The guide's reference footnote numbers for the row, within its table.}
#'   \item{GuideVersion}{`character` `"2.0"`.}
#'   \item{GuideSection}{`character` `"5.2.1"`, `"5.2.2"` or `"5.2.3"`.}
#'   \item{GuidePage}{`integer` Printed page of the guide the row is on.}
#'   \item{Note}{`character` Transcription note, else `NA`.}
#' }
#' @source FDA CDER, *Standard Safety Tables and Figures: Integrated Guide*,
#'   version 2.0, April 2025, Appendix 5.2,
#'   <https://www.fda.gov/media/187065/download>.
#' @seealso [FDA_AbnormalityLevels] for the abnormality level criteria,
#'   `Derive_ExtremeValueFlag()` (gsm.safety#78) for the exclusion rule applied to lab data.
#' @examples
#' data(FDA_ExtremeValues)
#' subset(FDA_ExtremeValues, Parameter == "Glucose")
"FDA_ExtremeValues"
