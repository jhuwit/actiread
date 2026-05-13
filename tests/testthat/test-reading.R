testthat::context("Reading baseline data")

try_ggir_read = function(fname) {
  file = system.file("testfiles", fname, package = "GGIR")
  if (!file.exists(file)) {
    file = system.file("testfiles", fname, package = "GGIRread")
  }
  file
}

testthat::test_that("GT3X reading works", {
  path = system.file(
    "extdata",
    "TAS1H30182785_2019-09-17.gt3x.gz",
    package = "actibase"
  )
  res = ab_read_gt3x(path, verbose = FALSE)
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_equal(mean(res$X), -0.0742151351351352)

  header = attr(res, "header")
  if (!is.null(header)) {
    dob = header$Value[header$Field == "DateOfBirth"]
    if (length(dob) > 0) {
      actibase:::ticks2datetime(dob)
    }
  }
})

testthat::test_that("bad file errors", {
  testthat::expect_error(ab_read_gt3x("blah.exe", verbose = FALSE))
})

testthat::test_that("preprocessing helpers work", {
  testthat::skip_if_not_installed("agcounts")

  path = system.file(
    "extdata",
    "TAS1H30182785_2019-09-17.gt3x.gz",
    package = "actibase"
  )
  res = ab_read_gt3x(path, verbose = FALSE)

  std = ab_standardize_data(res)
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(std)))

  resampled = ab_resample(std, sample_rate = 30L)
  testthat::expect_equal(attr(resampled, "sample_rate"), 30L)
  testthat::expect_true("transformations" %in% names(attributes(resampled)))

  counts = ab_calculate_counts(resampled, 60L)
  testthat::expect_true(all(c("time", "counts") %in% names(counts)))

  wear = ab_calculate_nonwear(counts, method = "choi")
  testthat::expect_true(all(c("time", "wear") %in% names(wear)))
})

testthat::test_that("CWA reading works", {
  file = try_ggir_read("ax3_testfile.cwa")
  if (file.exists(file)) {
    res = ab_read_cwa(file, verbose = FALSE)
    testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
    testthat::expect_true(mean(res$X) > -10)
  }

  cwa_gz = system.file("extdata", "ax3_testfile.cwa.gz", package = "actibase")
  if (file.exists(cwa_gz)) {
    res = ab_read_cwa(cwa_gz, verbose = FALSE)
    testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  }
})
