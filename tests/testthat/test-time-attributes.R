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
