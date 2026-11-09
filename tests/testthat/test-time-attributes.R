make_fake = function(time, header = list(
  TimeZone = NULL,
  accrange = 8,
  frequency = 100L,
  start = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
)) {
  list(
    header = header,
    data = data.frame(time = time, X = seq_along(time))
  )
}

t0 = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")

testthat::test_that("GT3X helper sets missing/unsorted time attributes", {
  res = suppressWarnings(actiread:::acti_gt3x_process_time(
    make_fake(t0 + 0:2), apply_tz = FALSE, verbose = FALSE))
  testthat::expect_false(attr(res, "missing_time"))
  testthat::expect_false(attr(res, "unsorted_time"))

  # suppress the unrelated header start-mismatch warning
  suppressWarnings(testthat::expect_warning(
    res <- actiread:::acti_gt3x_process_time(
      make_fake(t0 + c(2, 0, 1)), apply_tz = FALSE, verbose = FALSE),
    "not sorted"))
  testthat::expect_true(attr(res, "unsorted_time"))
  testthat::expect_false(attr(res, "missing_time"))

  res = suppressWarnings(actiread:::acti_gt3x_process_time(
    make_fake(c(t0, NA, t0 + 1)), apply_tz = FALSE, verbose = FALSE))
  testthat::expect_true(attr(res, "missing_time"))
  testthat::expect_false(attr(res, "unsorted_time"))
})

testthat::test_that("GT3X helper carries forward an unsorted flag", {
  fake = make_fake(t0 + 0:2)
  attr(fake, "unsorted_time") = TRUE
  res = suppressWarnings(actiread:::acti_gt3x_process_time(
    fake, apply_tz = FALSE, verbose = FALSE))
  testthat::expect_true(attr(res, "unsorted_time"))

  attr(fake, "unsorted_time") = NA
  res = suppressWarnings(actiread:::acti_gt3x_process_time(
    fake, apply_tz = FALSE, verbose = FALSE))
  testthat::expect_false(attr(res, "unsorted_time"))
})

testthat::test_that("CWA helper sets missing/unsorted time attributes", {
  res = suppressWarnings(actiread:::acti_cwa_process_time(
    make_fake(t0 + 0:2), apply_tz = FALSE, verbose = FALSE))
  testthat::expect_false(attr(res, "missing_time"))
  testthat::expect_false(attr(res, "unsorted_time"))

  res = suppressWarnings(actiread:::acti_cwa_process_time(
    make_fake(c(t0 + 2, NA, t0)), apply_tz = FALSE, verbose = FALSE))
  testthat::expect_true(attr(res, "missing_time"))
  testthat::expect_true(attr(res, "unsorted_time"))
})

testthat::test_that("readers expose time attributes on shipped examples", {
  gt3x = actiread::acti_read_gt3x(actiread::acti_example_gt3x(),
                                  verbose = FALSE, fill_zeroes = FALSE)
  testthat::expect_identical(attr(gt3x, "missing_time"), FALSE)
  testthat::expect_identical(attr(gt3x, "unsorted_time"), FALSE)
})

testthat::test_that("time_qc_flags flags and warns on missing/unsorted times", {
  flags = actiread:::time_qc_flags(1:3, "dev")
  testthat::expect_identical(flags,
                             list(missing_time = FALSE, unsorted_time = FALSE))

  testthat::expect_warning(
    flags <- actiread:::time_qc_flags(c(3, 1, 2), "dev"),
    "Times in dev data are not sorted")
  testthat::expect_true(flags$unsorted_time)

  testthat::expect_warning(
    flags <- actiread:::time_qc_flags(c(1, NA, 2), "dev"),
    "Some missing times in dev data")
  testthat::expect_true(flags$missing_time)
  testthat::expect_false(flags$unsorted_time)

  flags = actiread:::time_qc_flags(NULL, "dev")
  testthat::expect_identical(flags,
                             list(missing_time = NA, unsorted_time = NA))
})

testthat::test_that("other device readers expose time attributes", {
  readers = list(
    genea = function() actiread::acti_read_genea(
      actiread::acti_example_genea(), verbose = FALSE),
    geneactiv = function() actiread::acti_read_geneactiv(
      actiread::acti_example_geneactiv(), verbose = FALSE),
    matrix = function() actiread::acti_read_parmay_matrix(
      actiread::acti_example_parmay_matrix(), verbose = FALSE)
  )
  for (nm in names(readers)) {
    res = readers[[nm]]()
    testthat::expect_identical(attr(res, "missing_time"), FALSE, info = nm)
    testthat::expect_identical(attr(res, "unsorted_time"), FALSE, info = nm)
  }
})
