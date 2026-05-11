test_that("default table map uses GSM mapped domains", {
  expect_equal(
    sg_default_table_map(),
    c(dm = "Mapped_SUBJ", aes = "Mapped_AE", labs = "Mapped_LB")
  )
})

test_that("default mapping prefers existing gsm.mapping fields", {
  mapping <- sg_default_mapping()

  expect_equal(mapping$dm$id_col, "subjid")
  expect_null(mapping$dm$treatment_col)
  expect_equal(mapping$aes$term_col, "mdrpt_nsv")
  expect_equal(mapping$aes$bodsys_col, "mdrsoc_nsv")
  expect_equal(mapping$labs$measure_col, "toxgrg_nsv")
  expect_null(mapping$labs$value_col)
})

test_that("field contract documents pass-through fields and gaps", {
  contract <- sg_field_contract()

  expect_s3_class(contract, "data.frame")
  expect_true(all(c("domain", "table", "safety_key", "gsm_field", "requirement", "source", "notes") %in% names(contract)))
  expect_true(any(contract$domain == "labs" & contract$requirement == "chart_gap"))
  expect_true(any(contract$domain == "dm" & contract$safety_key == "treatment_col" & contract$requirement == "optional_gap"))
})

test_that("domain data adapter passes through mapped tables", {
  lData <- list(
    Mapped_SUBJ = data.frame(subjid = "01", agerep = 70, sex = "F", race = "WHITE"),
    Mapped_AE = data.frame(subjid = "01", mdrpt_nsv = "Headache", mdrsoc_nsv = "Nervous system disorders"),
    Mapped_LB = data.frame(subjid = "01", toxgrg_nsv = "ALT", lb_dt = as.Date("2026-01-01"))
  )

  domain_data <- sg_domain_data(lData)

  expect_named(domain_data, c("dm", "aes", "labs"))
  expect_identical(domain_data$dm, lData$Mapped_SUBJ)
  expect_identical(domain_data$aes, lData$Mapped_AE)
  expect_identical(domain_data$labs, lData$Mapped_LB)
})

test_that("labs domain is optional", {
  lData <- list(
    Mapped_SUBJ = data.frame(subjid = "01"),
    Mapped_AE = data.frame(subjid = "01", mdrpt_nsv = "Headache", mdrsoc_nsv = "Nervous system disorders")
  )

  domain_data <- sg_domain_data(lData)
  expect_named(domain_data, c("dm", "aes"))
  expect_true(sg_validate_data_contract(lData))
})

test_that("validation reports missing required tables and columns", {
  expect_error(
    sg_domain_data(list(Mapped_SUBJ = data.frame(subjid = "01"))),
    "Missing required lData table `Mapped_AE`"
  )

  bad_lData <- list(
    Mapped_SUBJ = data.frame(subject = "01"),
    Mapped_AE = data.frame(subjid = "01", mdrpt_nsv = "Headache", mdrsoc_nsv = "Nervous system disorders")
  )

  expect_error(
    sg_validate_data_contract(bad_lData),
    "Mapped_SUBJ.subjid"
  )
})
