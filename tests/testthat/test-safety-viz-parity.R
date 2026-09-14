# Offline half of the safety.viz parity guard (#49): the declared wrapped
# version, the vendored bundle, and every widget binding must agree. The
# cross-repo half — is that version safety.viz's latest release, and is every
# exported renderer wrapped — runs in CI (.github/workflows/safety-viz-parity.yaml),
# where the network belongs.

test_that("DESCRIPTION declares the wrapped safety.viz version (#49)", {
  strVersion <- utils::packageDescription("gsm.safety")[["Config/safetyviz/version"]]
  expect_true(is.character(strVersion) && nzchar(strVersion))
  expect_match(strVersion, "^\\d+[.]\\d+[.]\\d+$")
})

test_that("exactly one safety.viz bundle is vendored, at the declared version (#49)", {
  strVersion <- utils::packageDescription("gsm.safety")[["Config/safetyviz/version"]]
  strLibDir <- system.file("htmlwidgets", "lib", package = "gsm.safety")
  chrBundles <- list.files(strLibDir, pattern = "^safety[.]viz-")

  expect_identical(chrBundles, paste0("safety.viz-", strVersion))
  expect_true(file.exists(
    file.path(strLibDir, chrBundles, "safety.viz.js")
  ))
})

test_that("every widget binding depends on the declared safety.viz version (#49)", {
  strVersion <- utils::packageDescription("gsm.safety")[["Config/safetyviz/version"]]
  strWidgetDir <- system.file("htmlwidgets", package = "gsm.safety")
  chrYaml <- list.files(strWidgetDir, pattern = "^Widget_.*[.]yaml$", full.names = TRUE)
  expect_gt(length(chrYaml), 0)

  for (strFile in chrYaml) {
    lDependency <- yaml::read_yaml(strFile)$dependencies[[1]]
    expect_identical(
      as.character(lDependency$version),
      strVersion,
      label = paste0(basename(strFile), " version")
    )
    expect_identical(
      lDependency$src,
      paste0("htmlwidgets/lib/safety.viz-", strVersion),
      label = paste0(basename(strFile), " src")
    )
  }
})

test_that("every exported widget has a vendored data contract (#49)", {
  chrExported <- grep("^Widget_", getNamespaceExports("gsm.safety"), value = TRUE)
  expect_gt(length(chrExported), 0)

  chrSchemas <- list.files(system.file("schema", package = "gsm.safety"))
  # Widget_HepWaterfall -> hep-waterfall.json
  chrExpected <- paste0(
    gsub("^-", "", tolower(gsub("([A-Z])", "-\\1", sub("^Widget_", "", chrExported)))),
    ".json"
  )
  for (strSchema in chrExpected) {
    expect_true(strSchema %in% chrSchemas, label = strSchema)
  }
})
