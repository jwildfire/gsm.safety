# The FDA appendix reference criteria as package data (#77, hub obot.roadmap#9).
#
# Source: FDA Standard Safety Tables and Figures: Integrated Guide v2.0,
# April 2025, Appendix 5 — Tables 56 and 57 (abnormality levels) and Tables 58
# to 60 (extreme values). Row counts and spot values below were read from the
# PDF (https://www.fda.gov/media/187065/download) at the printed page cited
# beside each; the transcription itself lives in data-raw/.

RowsFor <- function(df, nTable) df[df$Table == nTable, , drop = FALSE]

# ---- Shape -----------------------------------------------------------------------

test_that("FDA_AbnormalityLevels carries every row of Tables 56 and 57 (#77)", {
  # Table 56: 22 general chemistry rows (glucose high split fasting/random),
  # 2 kidney, 4 liver, 5 lipid (HDL split by sex) — pages 119 to 120.
  # Table 57: 7 complete blood count, 4 differential, 2 coagulation — page 121.
  expect_identical(nrow(RowsFor(FDA_AbnormalityLevels, 56)), 33L)
  expect_identical(nrow(RowsFor(FDA_AbnormalityLevels, 57)), 13L)
  expect_identical(nrow(FDA_AbnormalityLevels), 46L)
  expect_setequal(unique(FDA_AbnormalityLevels$Table), c(56L, 57L))

  expect_identical(
    names(FDA_AbnormalityLevels),
    c(
      "Table", "Panel", "Parameter", "Direction", "Qualifier", "Unit", "Basis",
      "Operator", "Level1", "Level2", "Level3", "Level1Text", "Level2Text",
      "Level3Text", "GuideVersion", "GuideSection", "GuidePage", "Note"
    )
  )
  expect_true(is.numeric(FDA_AbnormalityLevels$Level1))
  expect_true(is.numeric(FDA_AbnormalityLevels$Level2))
  expect_true(is.numeric(FDA_AbnormalityLevels$Level3))
})

test_that("FDA_ExtremeValues carries every row of Tables 58 to 60 in both unit systems (#77)", {
  # Table 58: 26 chemistry parameters (pages 122 to 123); Table 59: 9
  # hematology parameters (page 123); Table 60: 5 vital signs (page 124).
  # Each printed row becomes a US and an SI row.
  nPerSystem <- table(FDA_ExtremeValues$Table, FDA_ExtremeValues$UnitSystem)
  expect_identical(unname(nPerSystem["58", "US"]), 26L)
  expect_identical(unname(nPerSystem["59", "US"]), 9L)
  expect_identical(unname(nPerSystem["60", "US"]), 5L)
  expect_identical(nPerSystem[, "US"], nPerSystem[, "SI"])
  expect_identical(nrow(FDA_ExtremeValues), 80L)

  expect_identical(
    names(FDA_ExtremeValues),
    c(
      "Table", "Panel", "Parameter", "Specimen", "UnitSystem", "Unit", "Low",
      "High", "References", "GuideVersion", "GuideSection", "GuidePage", "Note"
    )
  )
  expect_true(is.numeric(FDA_ExtremeValues$Low))
  expect_true(is.numeric(FDA_ExtremeValues$High))
})

test_that("every extreme-value parameter has exactly one US and one SI row (#77)", {
  strKey <- paste(FDA_ExtremeValues$Table, FDA_ExtremeValues$Parameter, FDA_ExtremeValues$Specimen)
  lSystems <- split(FDA_ExtremeValues$UnitSystem, strKey)
  expect_identical(length(lSystems), 40L)
  for (strParam in names(lSystems)) {
    expect_setequal(lSystems[[strParam]], c("US", "SI"))
    expect_identical(length(lSystems[[strParam]]), 2L)
  }
})

# ---- Completeness: every analyte the guide lists --------------------------------

test_that("every Table 56 and Table 57 analyte is present (#77)", {
  expect_setequal(
    unique(RowsFor(FDA_AbnormalityLevels, 56)$Parameter),
    c(
      "Sodium", "Potassium", "Chloride", "Bicarbonate", "Blood urea nitrogen",
      "Glucose", "Calcium", "Magnesium", "Phosphate", "Protein (total)",
      "Albumin", "CPK", "Amylase", "Lipase",
      "Creatinine", "eGFR",
      "Alkaline phosphatase", "Alanine Aminotransferase",
      "Aspartate Aminotransferase", "Total Bilirubin",
      "Cholesterol (total)", "HDL", "LDL", "Triglycerides"
    )
  )
  expect_setequal(
    unique(RowsFor(FDA_AbnormalityLevels, 57)$Parameter),
    c(
      "WBC", "Hemoglobin", "Platelets",
      "Lymphocytes", "Neutrophils", "Eosinophils",
      "PT", "PTT"
    )
  )
  expect_setequal(
    unique(RowsFor(FDA_AbnormalityLevels, 56)$Panel),
    c("General Chemistry", "Kidney Function", "Liver Biochemistry", "Lipids")
  )
  expect_setequal(
    unique(RowsFor(FDA_AbnormalityLevels, 57)$Panel),
    c("Complete blood count", "WBC differential", "Coagulation studies")
  )
})

test_that("every Table 58, 59 and 60 parameter is present (#77)", {
  expect_setequal(
    unique(RowsFor(FDA_ExtremeValues, 58)$Parameter),
    c(
      "Sodium", "Potassium", "Chloride", "Bicarbonate", "Blood Urea Nitrogen",
      "Glucose", "Total Calcium", "Magnesium", "Phosphate", "Total Protein",
      "Albumin", "Total CPK", "Amylase", "Lipase", "Creatinine",
      "Creatinine Clearance", "eGFR", "Alkaline Phosphatase",
      "Alanine Aminotransferase", "Aspartate Aminotransferase", "GGT",
      "Total Bilirubin", "Total Cholesterol", "HDL", "LDL", "Triglycerides"
    )
  )
  expect_setequal(
    unique(RowsFor(FDA_ExtremeValues, 59)$Parameter),
    c(
      "Neutrophils", "Lymphocytes", "Eosinophils", "Hemoglobin", "Hematocrit",
      "Platelets", "PT", "PTT", "INR"
    )
  )
  expect_setequal(
    unique(RowsFor(FDA_ExtremeValues, 60)$Parameter),
    c(
      "Pulse", "Blood pressure systolic", "Blood pressure diastolic",
      "Respiration", "Temperature"
    )
  )
})

# ---- Internal consistency ------------------------------------------------------------

test_that("abnormality levels are cumulative: each level is at least as severe as the last (#77)", {
  for (i in seq_len(nrow(FDA_AbnormalityLevels))) {
    lRow <- FDA_AbnormalityLevels[i, ]
    nLevels <- c(lRow$Level1, lRow$Level2, lRow$Level3)
    nLevels <- nLevels[!is.na(nLevels)]
    if (length(nLevels) < 2) next
    # "<" rows get stricter as the threshold falls; ">" and ">=" rows as it rises.
    if (lRow$Operator == "<") {
      expect_true(all(diff(nLevels) < 0), info = paste(lRow$Parameter, lRow$Direction, lRow$Qualifier))
    } else {
      expect_true(all(diff(nLevels) > 0), info = paste(lRow$Parameter, lRow$Direction, lRow$Qualifier))
    }
  }
  expect_setequal(unique(FDA_AbnormalityLevels$Operator), c("<", ">", ">="))
  expect_setequal(
    unique(FDA_AbnormalityLevels$Basis),
    c("absolute", "uln_multiple", "baseline_multiple", "baseline_percent_decrease", "baseline_change")
  )
  # Every row has at least one level.
  expect_false(any(is.na(FDA_AbnormalityLevels$Level1) & is.na(FDA_AbnormalityLevels$Level2) & is.na(FDA_AbnormalityLevels$Level3)))
})

test_that("extreme-value thresholds bracket a plausible range and carry their provenance (#77)", {
  bBoth <- !is.na(FDA_ExtremeValues$Low) & !is.na(FDA_ExtremeValues$High)
  expect_true(all(FDA_ExtremeValues$Low[bBoth] < FDA_ExtremeValues$High[bBoth]))
  expect_false(any(is.na(FDA_ExtremeValues$Low) & is.na(FDA_ExtremeValues$High)))
  expect_true(all(FDA_ExtremeValues$GuideVersion == "2.0"))
  expect_true(all(FDA_AbnormalityLevels$GuideVersion == "2.0"))
  expect_identical(unique(RowsFor(FDA_ExtremeValues, 58)$GuideSection), "5.2.1")
  expect_identical(unique(RowsFor(FDA_ExtremeValues, 59)$GuideSection), "5.2.2")
  expect_identical(unique(RowsFor(FDA_ExtremeValues, 60)$GuideSection), "5.2.3")
  expect_identical(unique(RowsFor(FDA_AbnormalityLevels, 56)$GuideSection), "5.1.1")
  expect_identical(unique(RowsFor(FDA_AbnormalityLevels, 57)$GuideSection), "5.1.2")
  expect_false(any(is.na(FDA_ExtremeValues$References)))
  # The datasets are ASCII so R CMD check raises no marked-encoding note.
  for (df in list(FDA_AbnormalityLevels, FDA_ExtremeValues)) {
    for (strCol in names(df)[vapply(df, is.character, logical(1))]) {
      expect_false(any(grepl("[^ -~]", df[[strCol]])), info = strCol)
    }
  }
})

# ---- Spot values read from the PDF -----------------------------------------------------

Level <- function(strParameter, strDirection, strQualifier = NA) {
  df <- FDA_AbnormalityLevels
  b <- df$Parameter == strParameter & df$Direction == strDirection &
    (if (is.na(strQualifier)) is.na(df$Qualifier) else !is.na(df$Qualifier) & df$Qualifier == strQualifier)
  expect_identical(sum(b), 1L, info = paste(strParameter, strDirection, strQualifier))
  df[b, ]
}

Extreme <- function(strParameter, strSystem) {
  df <- FDA_ExtremeValues
  b <- df$Parameter == strParameter & df$UnitSystem == strSystem
  expect_identical(sum(b), 1L, info = paste(strParameter, strSystem))
  df[b, ]
}

test_that("Table 56 spot values match the guide (page 119 and 120) (#77)", {
  # Page 119
  lRow <- Level("Potassium", "high")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(5.5, 6, 6.5))
  expect_identical(lRow$Operator, ">")
  expect_identical(lRow$Unit, "mEq/L")

  lRow <- Level("Bicarbonate", "high")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(NA_real_, NA_real_, 30))

  lRow <- Level("Glucose", "high", "Fasting")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(100, 126, NA_real_))
  expect_identical(lRow$Operator, ">=")

  lRow <- Level("CPK", "high")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(3, 5, 10))
  expect_identical(lRow$Basis, "uln_multiple")
  expect_identical(lRow$Level3Text, ">10 x ULN")

  # Page 120
  lRow <- Level("Alanine Aminotransferase", "high")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(3, 5, 10))
  expect_identical(lRow$Basis, "uln_multiple")
  expect_identical(lRow$Panel, "Liver Biochemistry")

  lRow <- Level("Total Bilirubin", "high")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(1.5, 2, 3))

  lRow <- Level("Creatinine", "increase")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(1.5, 2, 3))
  expect_identical(lRow$Basis, "baseline_multiple")

  lRow <- Level("eGFR", "decrease")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(25, 50, 75))
  expect_identical(lRow$Basis, "baseline_percent_decrease")

  lRow <- Level("HDL", "low", "females")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(50, 40, 20))
  expect_identical(Level("HDL", "low", "males")$Level1, 40)
})

test_that("Table 57 spot values match the guide (page 121) (#77)", {
  lRow <- Level("WBC", "low")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(3.5, 3, 1))
  expect_identical(lRow$Unit, "x 10^9 cells/L")

  lRow <- Level("Hemoglobin", "decrease")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(NA_real_, 1.5, 2))
  expect_identical(lRow$Basis, "baseline_change")
  expect_identical(lRow$Level2Text, ">1.5 dec. from baseline")

  lRow <- Level("Platelets", "low")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(140000, 125000, 100000))
  expect_false(is.na(lRow$Note))

  lRow <- Level("Hemoglobin", "low", "male")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(13.5, 12.5, 10.5))
  expect_identical(lRow$Level1Text, "12.5-13.5")

  lRow <- Level("PTT", "increase")
  expect_identical(c(lRow$Level1, lRow$Level2, lRow$Level3), c(1.0, 1.21, 1.41))
  expect_identical(lRow$Basis, "uln_multiple")
})

test_that("Table 58 spot values match the guide (pages 122 and 123) (#77)", {
  # Page 122
  lRow <- Extreme("Glucose", "US")
  expect_identical(c(lRow$Low, lRow$High), c(10, 2700))
  expect_identical(lRow$Unit, "mg/dL")
  expect_identical(lRow$Specimen, "plasma")
  lRow <- Extreme("Glucose", "SI")
  expect_identical(c(lRow$Low, lRow$High), c(0.6, 150))
  expect_identical(lRow$Unit, "mmol/L")
  expect_identical(lRow$References, "2, 7")

  lRow <- Extreme("Alanine Aminotransferase", "US")
  expect_identical(c(lRow$Low, lRow$High), c(NA_real_, 50000))
  lRow <- Extreme("Alanine Aminotransferase", "SI")
  expect_identical(c(lRow$Low, lRow$High), c(NA_real_, 830))
  expect_identical(lRow$Unit, "ukat/L")

  lRow <- Extreme("Creatinine", "SI")
  expect_identical(c(lRow$Low, lRow$High), c(NA_real_, 7072))
  expect_identical(lRow$Unit, "umol/L")

  lRow <- Extreme("Total Bilirubin", "SI")
  expect_identical(lRow$High, 3420)

  # Page 123
  lRow <- Extreme("Triglycerides", "SI")
  expect_identical(c(lRow$Low, lRow$High), c(0.13, 90.7))
  expect_identical(lRow$GuidePage, 123L)
})

test_that("Table 59 and Table 60 spot values match the guide (pages 123 and 124) (#77)", {
  lRow <- Extreme("Hemoglobin", "US")
  expect_identical(c(lRow$Low, lRow$High), c(0.6, 30))
  expect_identical(lRow$Unit, "g/dL")
  lRow <- Extreme("Hemoglobin", "SI")
  expect_identical(c(lRow$Low, lRow$High), c(6, 300))
  expect_identical(lRow$Unit, "g/L")

  lRow <- Extreme("Platelets", "US")
  expect_identical(c(lRow$Low, lRow$High), c(NA_real_, 5e6))

  lRow <- Extreme("INR", "US")
  expect_identical(lRow$High, 20)
  expect_true(is.na(lRow$Unit))

  lRow <- Extreme("Pulse", "US")
  expect_identical(c(lRow$Low, lRow$High), c(10, 600))
  expect_identical(lRow$GuidePage, 124L)

  lRow <- Extreme("Blood pressure diastolic", "SI")
  expect_identical(c(lRow$Low, lRow$High), c(25, 370))
  expect_identical(lRow$Unit, "mmHg")

  expect_identical(Extreme("Temperature", "US")$Unit, "F")
  expect_identical(c(Extreme("Temperature", "US")$Low, Extreme("Temperature", "US")$High), c(50, 120))
  expect_identical(Extreme("Temperature", "SI")$Unit, "C")
  expect_identical(c(Extreme("Temperature", "SI")$Low, Extreme("Temperature", "SI")$High), c(10, 50))
})

# ---- Documentation and site ------------------------------------------------------------

test_that("the dataset help pages name the guide version and the tables they transcribe (#77)", {
  strMan <- testthat::test_path("..", "..", "man")
  skip_if_not(dir.exists(strMan), "man/ not available in this check context")

  strLevels <- paste(readLines(file.path(strMan, "FDA_AbnormalityLevels.Rd"), warn = FALSE), collapse = "\n")
  expect_match(strLevels, "version 2.0", fixed = TRUE)
  expect_match(strLevels, "Table 56", fixed = TRUE)
  expect_match(strLevels, "Table 57", fixed = TRUE)

  strExtreme <- paste(readLines(file.path(strMan, "FDA_ExtremeValues.Rd"), warn = FALSE), collapse = "\n")
  expect_match(strExtreme, "version 2.0", fixed = TRUE)
  for (strTable in c("Table 58", "Table 59", "Table 60")) {
    expect_match(strExtreme, strTable, fixed = TRUE)
  }
})

test_that("the pkgdown reference lists both datasets under FDA reference criteria (#77)", {
  strPath <- testthat::test_path("..", "..", "_pkgdown.yml")
  skip_if_not(file.exists(strPath), "_pkgdown.yml not available in this check context")

  lReference <- yaml::read_yaml(strPath)$reference
  chrTitles <- vapply(lReference, function(l) l$title, character(1))
  expect_true("FDA reference criteria" %in% chrTitles)
  chrContents <- lReference[[which(chrTitles == "FDA reference criteria")]]$contents
  expect_setequal(chrContents, c("FDA_AbnormalityLevels", "FDA_ExtremeValues"))
})
