# The first Derive_* functions: the guide's normative rules applied once, in R,
# over long-format lab data (#78, hub obot.roadmap#9). Each test names the
# requirement row in requirements/fda-stf.md it proves.

LabRows <- function(strTest, nValue, strUnit = "U/L", nLLN = 0, nULN = 40, strID = "S1") {
  data.frame(
    USUBJID = strID,
    TEST = strTest,
    STRESU = strUnit,
    STRESN = as.numeric(nValue),
    STNRLO = nLLN,
    STNRHI = nULN,
    stringsAsFactors = FALSE
  )
}

# ---- Derive_ULNMultiple ----------------------------------------------------------

test_that("Derive_ULNMultiple divides the result by the record's own ULN (FDA-RULE-001) (#78)", {
  df <- rbind(
    LabRows("Alanine Aminotransferase", c(20, 120, 200), nULN = 40),
    LabRows("Alanine Aminotransferase", 100, nULN = 50, strID = "S2")
  )
  out <- Derive_ULNMultiple(df)

  expect_identical(nrow(out), nrow(df))
  expect_identical(names(out), c(names(df), "ULNMultiple"))
  expect_identical(out$ULNMultiple, c(0.5, 3, 5, 2))
  # The input columns come back untouched, in order.
  expect_identical(out[, names(df)], df)
})

test_that("Derive_ULNMultiple leaves the multiple missing where the ULN is unusable (FDA-RULE-001) (#78)", {
  df <- LabRows("Alanine Aminotransferase", c(50, 50, 50, NA), nULN = c(0, NA, -1, 40))
  out <- Derive_ULNMultiple(df)
  expect_true(all(is.na(out$ULNMultiple)))
  expect_identical(nrow(out), 4L)
})

test_that("Derive_ULNMultiple takes its column names as arguments (FDA-RULE-001) (#78)", {
  df <- data.frame(id = "S1", lbstresn = 80, lbstnrhi = 40, stringsAsFactors = FALSE)
  out <- Derive_ULNMultiple(df, strValueCol = "lbstresn", strULNCol = "lbstnrhi", strOutCol = "xULN")
  expect_identical(out$xULN, 2)
  expect_error(Derive_ULNMultiple(df), "STRESN")
  expect_error(Derive_ULNMultiple(list()), "data.frame")
})

test_that("Derive_ULNMultiple runs on the example data and agrees with Input_HysLaw's peak multiples (FDA-RULE-001, FDA-RULE-008) (#78)", {
  dfLabs <- ExampleData("adbds")
  out <- Derive_ULNMultiple(dfLabs)
  expect_identical(nrow(out), nrow(dfLabs))
  expect_true(any(is.finite(out$ULNMultiple)))

  dfHys <- Input_HysLaw(
    dfLabs,
    strIDCol = "USUBJID", strMeasureCol = "TEST",
    strValueCol = "STRESN", strULNCol = "STNRHI"
  )
  lMeasures <- list(
    PeakALT_xULN = "Alanine Aminotransferase",
    PeakAST_xULN = "Aspartate Aminotransferase",
    PeakTB_xULN = "Bilirubin",
    PeakALP_xULN = "Alkaline Phosphatase"
  )
  for (strPeak in names(lMeasures)) {
    bRow <- out$TEST == lMeasures[[strPeak]] & is.finite(out$ULNMultiple)
    vPeak <- tapply(out$ULNMultiple[bRow], out$USUBJID[bRow], max)
    nExpected <- round(as.numeric(vPeak[dfHys$SubjectID]), 3)
    expect_equal(dfHys[[strPeak]], nExpected, info = strPeak)
  }
})

# ---- Derive_AbnormalityLevel --------------------------------------------------------

test_that("Derive_AbnormalityLevel grades every absolute threshold direction in Tables 56 and 57 (FDA-RULE-002) (#78)", {
  dfCriteria <- FDA_AbnormalityLevels
  bRow <- dfCriteria$Basis == "absolute" & is.na(dfCriteria$Qualifier)
  expect_gt(sum(bRow), 20)

  for (i in which(bRow)) {
    lRow <- dfCriteria[i, ]
    # Probe just beyond each defined level, and one value on the normal side.
    nLevels <- c(lRow$Level1, lRow$Level2, lRow$Level3)
    nDefined <- which(!is.na(nLevels))
    nStep <- if (lRow$Operator == "<") -0.01 else 0.01
    nProbe <- c(nLevels[nDefined] + nStep, nLevels[nDefined[1]] - nStep)
    nExpect <- c(nDefined, 0L)
    # The equals case: ">=" rows meet the level on the threshold itself, the
    # strict rows do not.
    nProbe <- c(nProbe, nLevels[nDefined[1]])
    nExpect <- c(nExpect, if (lRow$Operator == ">=") nDefined[1] else 0L)

    df <- LabRows("probe", nProbe, strUnit = lRow$Unit)
    out <- Derive_AbnormalityLevel(
      df,
      lParameterValues = stats::setNames(list("probe"), lRow$Parameter),
      dfCriteria = lRow
    )
    expect_identical(
      out$AbnormalityLevel, as.integer(nExpect),
      info = paste(lRow$Table, lRow$Parameter, lRow$Direction)
    )
    expect_identical(
      out$AbnormalityDirection,
      ifelse(nExpect > 0, lRow$Direction, NA_character_),
      info = paste(lRow$Table, lRow$Parameter, lRow$Direction)
    )
  }
})

test_that("Derive_AbnormalityLevel grades the ULN-multiple rows on the multiple, whatever the unit (FDA-RULE-001, FDA-RULE-002) (#78)", {
  dfCriteria <- FDA_AbnormalityLevels[FDA_AbnormalityLevels$Basis == "uln_multiple", ]
  expect_identical(nrow(dfCriteria), 9L)
  for (i in seq_len(nrow(dfCriteria))) {
    lRow <- dfCriteria[i, ]
    nULN <- 37
    df <- LabRows(
      "probe",
      nULN * c(lRow$Level1 + 0.01, lRow$Level2 + 0.01, lRow$Level3 + 0.01, lRow$Level1 - 0.01, lRow$Level1),
      strUnit = "anything", nULN = nULN
    )
    out <- Derive_AbnormalityLevel(
      df,
      lParameterValues = stats::setNames(list("probe"), lRow$Parameter),
      dfCriteria = lRow
    )
    expect_identical(out$AbnormalityLevel, c(1L, 2L, 3L, 0L, 0L), info = lRow$Parameter)
  }
})

test_that("Derive_AbnormalityLevel reports the highest level met across a parameter's directions (FDA-RULE-002) (#78)", {
  # Potassium: low <3.6/<3.4/<3.0, high >5.5/>6/>6.5 (Table 56, page 119).
  df <- LabRows("Potassium", c(2.5, 3.5, 4.5, 5.6, 6.6), strUnit = "mmol/L")
  out <- Derive_AbnormalityLevel(df)
  expect_identical(out$AbnormalityLevel, c(3L, 1L, 0L, 1L, 3L))
  expect_identical(out$AbnormalityDirection, c("low", "low", NA, "high", "high"))
  expect_identical(out$AbnormalityCriterion, c("<3.0", "<3.6", NA, ">5.5", ">6.5"))
  expect_identical(names(out), c(names(df), "AbnormalityLevel", "AbnormalityDirection", "AbnormalityCriterion"))
})

test_that("Derive_AbnormalityLevel grades absolute thresholds only in a matching unit and says what it skipped (FDA-RULE-002) (#78)", {
  # Glucose low <70 mg/dL: the example data carry glucose in mmol/L, which is
  # not the criteria's unit, so the row is not graded rather than misgraded.
  df <- rbind(
    LabRows("Glucose", 3.9, strUnit = "mmol/L"),
    LabRows("Glucose", 60, strUnit = "mg/dL")
  )
  expect_message(out <- Derive_AbnormalityLevel(df), "unit")
  expect_identical(out$AbnormalityLevel, c(NA_integer_, 1L))
  # mEq/L and mmol/L are the same number for the monovalent electrolytes, and
  # the WBC count's "x 10^9 cells/L" is GI/L.
  expect_identical(Derive_AbnormalityLevel(LabRows("Sodium", 124, strUnit = "mmol/L"))$AbnormalityLevel, 3L)
  expect_identical(Derive_AbnormalityLevel(LabRows("Leukocytes", 0.9, strUnit = "GI/L"))$AbnormalityLevel, 3L)
})

test_that("Derive_AbnormalityLevel leaves unlisted parameters and baseline-relative rows ungraded (FDA-RULE-002) (#78)", {
  df <- rbind(
    LabRows("Weight", 80, strUnit = "kg"),
    LabRows("Creatinine", 300, strUnit = "umol/L"),
    LabRows("Hemoglobin", 5, strUnit = "mmol/L")
  )
  out <- suppressMessages(Derive_AbnormalityLevel(df))
  expect_identical(out$AbnormalityLevel, rep(NA_integer_, 3))
  expect_identical(out$AbnormalityDirection, rep(NA_character_, 3))
})

test_that("Derive_AbnormalityLevel applies the sex-qualified rows only with a sex column (FDA-RULE-016) (#78)", {
  df <- rbind(
    LabRows("HDL", 45, strUnit = "mg/dL", strID = "F1"),
    LabRows("HDL", 45, strUnit = "mg/dL", strID = "M1")
  )
  df$SEX <- c("F", "M")
  # Without a sex column the HDL rows (males, females) cannot be applied.
  expect_message(out <- Derive_AbnormalityLevel(df, lParameterValues = list(HDL = "HDL")), "sex")
  expect_identical(out$AbnormalityLevel, c(NA_integer_, NA_integer_))
  # With one: <50 is level 1 for females and normal for males.
  out <- Derive_AbnormalityLevel(df, lParameterValues = list(HDL = "HDL"), strSexCol = "SEX")
  expect_identical(out$AbnormalityLevel, c(1L, 0L))
  # Hemoglobin low, female: 11.0-12.0 / <11 / <9.5 (Table 57, page 121).
  dfHgb <- LabRows("Hemoglobin", c(11.5, 10, 9), strUnit = "g/dL", strID = "F1")
  dfHgb$SEX <- "Female"
  # The hemoglobin change-from-baseline rows are reported as skipped; the
  # sex-qualified absolute rows still grade.
  expect_message(
    out <- Derive_AbnormalityLevel(dfHgb, lParameterValues = list(Hemoglobin = "Hemoglobin"), strSexCol = "SEX"),
    "baseline"
  )
  expect_identical(out$AbnormalityLevel, c(1L, 2L, 3L))
})

test_that("Derive_AbnormalityLevel accepts a substitute criteria table (FDA-RULE-003) (#78)", {
  dfMine <- data.frame(
    Table = 0L, Panel = "Custom", Parameter = "Widgets", Direction = "high", Qualifier = NA_character_,
    Unit = "U/L", Basis = "absolute", Operator = ">", Level1 = 10, Level2 = 20, Level3 = 30,
    Level1Text = ">10", Level2Text = ">20", Level3Text = ">30", stringsAsFactors = FALSE
  )
  out <- Derive_AbnormalityLevel(
    LabRows("W", c(5, 15, 25, 35)),
    dfCriteria = dfMine, lParameterValues = list(Widgets = "W")
  )
  expect_identical(out$AbnormalityLevel, c(0L, 1L, 2L, 3L))
  expect_error(Derive_AbnormalityLevel(LabRows("W", 1), dfCriteria = dfMine[, -8]), "Operator")
})

test_that("Derive_AbnormalityLevel runs on the example data with the default parameter map (FDA-RULE-002) (#78)", {
  dfLabs <- ExampleData("adbds")
  out <- suppressMessages(Derive_AbnormalityLevel(dfLabs))
  expect_identical(nrow(out), nrow(dfLabs))
  expect_identical(out[, names(dfLabs)], dfLabs)
  # The liver panel is graded on ULN multiples, so it is gradable whatever the unit.
  bALT <- out$TEST == "Alanine Aminotransferase" & is.finite(out$STRESN) & is.finite(out$STNRHI) & out$STNRHI > 0
  expect_false(any(is.na(out$AbnormalityLevel[bALT])))
  expect_true(any(out$AbnormalityLevel[bALT] > 0))
  # Vital signs are not in Tables 56 and 57.
  expect_true(all(is.na(out$AbnormalityLevel[out$TEST == "Systolic Blood Pressure"])))
})

# ---- Derive_ExtremeValueFlag --------------------------------------------------------

test_that("Derive_ExtremeValueFlag flags a value beyond the threshold in either unit system (FDA-RULE-004, FDA-RULE-005) (#78)", {
  # Glucose (plasma): <10 / >2700 mg/dL; <0.6 / >150 mmol/L (Table 58, page 122).
  df <- rbind(
    LabRows("Glucose", c(5, 100, 2800), strUnit = "mg/dL"),
    LabRows("Glucose", c(0.5, 5.5, 151), strUnit = "mmol/L")
  )
  out <- Derive_ExtremeValueFlag(df)
  expect_identical(out$ExtremeValueFlag, c(TRUE, FALSE, TRUE, TRUE, FALSE, TRUE))
  expect_identical(out$ExtremeValueDirection, c("low", NA, "high", "low", NA, "high"))
  expect_identical(names(out), c(names(df), "ExtremeValueFlag", "ExtremeValueDirection"))
  expect_identical(out[, names(df)], df)
})

test_that("Derive_ExtremeValueFlag treats a missing threshold as no bound in that direction (FDA-RULE-004) (#78)", {
  # ALT (serum): N/A low, >50,000 U/L high.
  df <- LabRows("Alanine Aminotransferase", c(0, 1, 50000, 50001), strUnit = "U/L")
  out <- Derive_ExtremeValueFlag(df)
  expect_identical(out$ExtremeValueFlag, c(FALSE, FALSE, FALSE, TRUE))
  # A threshold is exclusive: the printed value itself is not extreme.
  df <- LabRows("Pulse Rate", c(10, 600, 9, 601), strUnit = "BEATS/MIN")
  expect_identical(Derive_ExtremeValueFlag(df)$ExtremeValueFlag, c(FALSE, FALSE, TRUE, TRUE))
})

test_that("Derive_ExtremeValueFlag honours the unit column and says what it could not match (FDA-RULE-005) (#78)", {
  # Hemoglobin thresholds are in g/dL and g/L; the example data carry mmol/L.
  df <- rbind(
    LabRows("Hemoglobin", 4, strUnit = "mmol/L"),
    LabRows("Hemoglobin", 0.5, strUnit = "g/dL"),
    LabRows("Hemoglobin", 301, strUnit = "g/L"),
    LabRows("Weight", 500, strUnit = "kg")
  )
  expect_message(out <- Derive_ExtremeValueFlag(df), "unit")
  expect_identical(out$ExtremeValueFlag, c(NA, TRUE, TRUE, NA))
  # Temperature: 50 to 120 F, 10 to 50 C.
  dfT <- rbind(LabRows("Temperature", c(9, 37), strUnit = "C"), LabRows("Temperature", c(121, 98), strUnit = "F"))
  expect_identical(Derive_ExtremeValueFlag(dfT)$ExtremeValueFlag, c(TRUE, FALSE, TRUE, FALSE))
})

test_that("Derive_ExtremeValueFlag applies the unitless INR row to a blank or missing unit (FDA-RULE-004, FDA-RULE-005) (#138)", {
  # INR (Table 59, page 123): the guide prints N/A for both units; extreme above 20.
  df <- data.frame(
    TEST = "INR",
    STRESN = c(19, 20, 21, 25, 19, 21),
    STRESU = c(NA, NA, NA, NA, "", ""),
    stringsAsFactors = FALSE
  )
  out <- Derive_ExtremeValueFlag(df, lParameterValues = list(INR = "INR"))
  expect_identical(out$ExtremeValueFlag, c(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE))
  expect_identical(out$ExtremeValueDirection, c(NA, NA, "high", "high", NA, "high"))
  # A unit the row does not print is not matched, and the message says which.
  dfUnit <- data.frame(TEST = "INR", STRESN = 21, STRESU = "ratio", stringsAsFactors = FALSE)
  expect_message(
    outUnit <- Derive_ExtremeValueFlag(dfUnit, lParameterValues = list(INR = "INR")),
    "INR in ratio"
  )
  expect_identical(outUnit$ExtremeValueFlag, NA)
})

test_that("Derive_ExtremeValueFlag runs on the example data and flags nothing in the pilot labs (FDA-RULE-004) (#78)", {
  dfLabs <- ExampleData("adbds")
  out <- suppressMessages(Derive_ExtremeValueFlag(dfLabs))
  expect_identical(nrow(out), nrow(dfLabs))
  bMatched <- !is.na(out$ExtremeValueFlag)
  # Sodium, potassium, bilirubin, the transaminases and the vital signs match in
  # the data's own units; hemoglobin in mmol/L does not.
  expect_true(all(c("Sodium", "Bilirubin", "Alanine Aminotransferase", "Systolic Blood Pressure") %in% out$TEST[bMatched]))
  expect_false("Hemoglobin" %in% out$TEST[bMatched])
  expect_identical(sum(out$ExtremeValueFlag, na.rm = TRUE), 0L)
})

test_that("the Derive_* functions take a parameter map and error on a missing column (#78)", {
  df <- LabRows("Natrium", 200, strUnit = "mmol/L")
  expect_true(is.na(suppressMessages(Derive_ExtremeValueFlag(df))$ExtremeValueFlag))
  expect_true(Derive_ExtremeValueFlag(df, lParameterValues = list(Sodium = "Natrium"))$ExtremeValueFlag)
  expect_identical(Derive_AbnormalityLevel(df, lParameterValues = list(Sodium = "Natrium"))$AbnormalityLevel, 3L)
  expect_error(Derive_ExtremeValueFlag(df, strUnitCol = "UNIT"), "UNIT")
  expect_error(Derive_AbnormalityLevel(df, strTestCol = "PARAM"), "PARAM")
})

# ---- Review fixes on the v1.5.0 candidate (#88) --------------------------------------

test_that("the Derive_* output-name arguments must carry the token their sibling columns are named from (#78)", {
  df <- LabRows("Potassium", 7, strUnit = "mmol/L")
  expect_error(Derive_AbnormalityLevel(df, strOutCol = "Grade"), "Level")
  expect_error(Derive_ExtremeValueFlag(df, strOutCol = "Extreme"), "Flag")
  out <- Derive_AbnormalityLevel(df, strOutCol = "KLevel")
  expect_identical(names(out)[(ncol(out) - 2):ncol(out)], c("KLevel", "KDirection", "KCriterion"))
  expect_identical(out$KLevel, 3L)
  out <- Derive_ExtremeValueFlag(df, strOutCol = "XFlag")
  expect_identical(names(out)[(ncol(out) - 1):ncol(out)], c("XFlag", "XDirection"))
})

test_that("mEq/L is read as mmol/L for the monovalent electrolytes only (FDA-RULE-005) (#78)", {
  # Sodium 191 mEq/L is 191 mmol/L: the SI row's high threshold, not extreme; 192 is.
  expect_identical(Derive_ExtremeValueFlag(LabRows("Sodium", c(191, 192), strUnit = "mEq/L"))$ExtremeValueFlag, c(FALSE, TRUE))
  expect_identical(Derive_AbnormalityLevel(LabRows("Sodium", 124, strUnit = "mEq/L"))$AbnormalityLevel, 3L)
  # Magnesium 7 mEq/L is 3.5 mmol/L, inside the guide's SI range; it must not be
  # compared against the mmol/L row as if it were 7 mmol/L. The guide prints
  # magnesium in mg/dL and mmol/L, so mEq/L matches neither and is left NA.
  expect_message(out <- Derive_ExtremeValueFlag(LabRows("Magnesium", 7, strUnit = "mEq/L")), "unit")
  expect_true(is.na(out$ExtremeValueFlag))
  expect_message(out <- Derive_ExtremeValueFlag(LabRows("Calcium", 5.5, strUnit = "mEq/L")), "unit")
  expect_true(is.na(out$ExtremeValueFlag))
  expect_message(out <- Derive_AbnormalityLevel(LabRows("Magnesium", 3, strUnit = "mEq/L")), "unit")
  expect_true(is.na(out$AbnormalityLevel))
})

test_that("the platelet row grades a per-microlitre count and the CDISC giga-per-litre spelling is read (FDA-RULE-002) (#78)", {
  # Table 57 prints platelets with the unit x 10^9 cells/uL beside thresholds of
  # 140,000; the row is filed in cells/uL (the Note records the misprint).
  expect_identical(
    Derive_AbnormalityLevel(LabRows("Platelet", c(150000, 130000, 90000), strUnit = "/uL"))$AbnormalityLevel,
    c(0L, 1L, 3L)
  )
  expect_identical(Derive_AbnormalityLevel(LabRows("Leukocytes", 0.9, strUnit = "10*9/L"))$AbnormalityLevel, 3L)
  expect_identical(Derive_AbnormalityLevel(LabRows("Leukocytes", 0.9, strUnit = "10^9/L"))$AbnormalityLevel, 3L)
})

test_that("the Derive_* functions refuse to overwrite an input column that shares an output name (#102)", {
  df <- LabRows("Potassium", 7, strUnit = "mmol/L")

  # The requested column itself: the source result would be replaced.
  expect_error(Derive_ULNMultiple(df, strOutCol = "STRESN"), "'STRESN' already exists")
  expect_error(Derive_ULNMultiple(df, strOutCol = "STNRHI"), "'STNRHI' already exists")
  dfLevel <- df
  dfLevel$AbnormalityLevel <- 0L
  expect_error(Derive_AbnormalityLevel(dfLevel), "'AbnormalityLevel' already exists")
  dfFlag <- df
  dfFlag$ExtremeValueFlag <- FALSE
  expect_error(Derive_ExtremeValueFlag(dfFlag), "'ExtremeValueFlag' already exists")

  # A generated sibling: the input column would be replaced by the direction.
  dfDirection <- df
  dfDirection$AbnormalityDirection <- "source"
  expect_error(Derive_AbnormalityLevel(dfDirection), "'AbnormalityDirection' already exists")
  dfCriterion <- df
  dfCriterion$AbnormalityCriterion <- "source"
  expect_error(Derive_AbnormalityLevel(dfCriterion), "'AbnormalityCriterion' already exists")
  dfXDirection <- df
  dfXDirection$ExtremeValueDirection <- "source"
  expect_error(Derive_ExtremeValueFlag(dfXDirection), "'ExtremeValueDirection' already exists")

  # A frame without the names still gains exactly its new columns, in order.
  out <- Derive_ExtremeValueFlag(Derive_AbnormalityLevel(Derive_ULNMultiple(df)))
  expect_identical(
    setdiff(names(out), names(df)),
    c("ULNMultiple", "AbnormalityLevel", "AbnormalityDirection", "AbnormalityCriterion", "ExtremeValueFlag", "ExtremeValueDirection")
  )
  expect_identical(out[names(df)], df)

  # A name that is not one string, or is missing, is refused before anything is assigned.
  expect_error(Derive_ULNMultiple(df, strOutCol = 5), "single column name")
  expect_error(Derive_ULNMultiple(df, strOutCol = NA_character_), "single column name")
  expect_error(Derive_AbnormalityLevel(df, strOutCol = NA_character_), "Level")
  expect_error(Derive_ExtremeValueFlag(df, strOutCol = NA_character_), "Flag")
})
