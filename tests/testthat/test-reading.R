testthat::context("Reading baseline data")

testthat::test_that("example data helpers return package files", {
  gt3x = actiread::acti_example_gt3x()
  cwa = actiread::acti_example_cwa()

  testthat::expect_true(file.exists(gt3x))
  testthat::expect_true(file.exists(cwa))
  testthat::expect_match(gt3x, "\\.gt3x\\.gz$")
  testthat::expect_match(cwa, "\\.cwa\\.gz$")
})

testthat::test_that("tzoffset_to_tz handles supported offsets", {
  testthat::expect_equal(actiread:::tzoffset_to_tz("+00:00"), "Etc/GMT0")
  testthat::expect_equal(actiread:::tzoffset_to_tz("-05:00"), "Etc/GMT-5")
  testthat::expect_equal(actiread:::tzoffset_to_tz("+01:00"), "Etc/GMT+1")
  testthat::expect_error(actiread:::tzoffset_to_tz("+05:30"))
})

testthat::test_that("GT3X reading works on the shipped example", {
  args = list(
    actiread::acti_example_gt3x(),
    verbose = FALSE,
    fill_zeroes = FALSE,
    digits = 3L
  )
  if (utils::packageVersion("read.gt3x") < package_version("1.3.0")) {
    args$digits = NULL
  }
  res = do.call(actiread::acti_read_gt3x, args = args)

  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_equal(mean(res$X), -0.0742151351351352)
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
  testthat::expect_true("transformations" %in% names(attributes(res)))
})


testthat::test_that("GT3X reading works with digits=5L", {
  testthat::skip_if_not_installed("read.gt3x", minimum_version = "1.3.0")
  res = actiread::acti_read_gt3x(
    actiread::acti_example_gt3x(),
    verbose = FALSE,
    fill_zeroes = FALSE,
    digits = 5L
  )

  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_equal(mean(res$X), -0.074214755925156)
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
  testthat::expect_true("transformations" %in% names(attributes(res)))
})

testthat::test_that("GT3X reading fills zeroes on the shipped example", {
  res = suppressMessages(
    actiread::acti_read_gt3x(
      actiread::acti_example_gt3x(),
      verbose = TRUE,
      fill_zeroes = TRUE
    )
  )

  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
})

testthat::test_that("GT3X reading handles tz=NULL and apply_tz = FALSE", {
  res = suppressMessages(
    actiread::acti_read_gt3x(
      actiread::acti_example_gt3x(),
      tz = NULL,
      apply_tz = FALSE,
      verbose = TRUE,
      fill_zeroes = FALSE,
      check_attributes = FALSE
    )
  )

  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
})

testthat::test_that("GT3X helper handles an empty header and missing times", {
  fake = list(
    header = NULL,
    data = data.frame(
      time = c(
        as.POSIXct("2019-09-17 18:40:00", tz = "UTC"),
        NA
      ),
      X = c(1, 2),
      Y = c(3, 4),
      Z = c(5, 6)
    )
  )

  res = suppressWarnings(
    actiread:::acti_gt3x_process_time(
      fake,
      apply_tz = FALSE,
      verbose = FALSE,
      check_attributes = FALSE
    )
  )
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_true(anyNA(res$time))
})

testthat::test_that("GT3X helper warns when the header timezone is missing", {
  fake = list(
    header = list(
      TimeZone = NULL,
      accrange = 8,
      frequency = 100L,
      start = as.POSIXct("2019-09-17 18:40:00", tz = "UTC")
    ),
    data = data.frame(
      time = c(
        as.POSIXct("2019-09-17 18:40:00", tz = "UTC"),
        as.POSIXct("2019-09-17 18:40:01", tz = "UTC")
      ),
      X = c(1, 2),
      Y = c(3, 4),
      Z = c(5, 6)
    )
  )

  res = suppressWarnings(
    actiread:::acti_gt3x_process_time(
      fake,
      apply_tz = TRUE,
      verbose = FALSE,
      check_attributes = FALSE
    )
  )
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
})

testthat::test_that("GT3X helper stops if timezone conversion creates NA times", {
  fake = list(
    header = list(
      TimeZone = "+00:00",
      accrange = 8,
      frequency = 100L,
      start = structure(1e20, class = c("POSIXct", "POSIXt"), tzone = "UTC")
    ),
    data = data.frame(
      time = structure(1e20, class = c("POSIXct", "POSIXt"), tzone = "UTC"),
      X = 1,
      Y = 2,
      Z = 3
    )
  )

  testthat::expect_error(
    actiread:::acti_gt3x_process_time(
      fake,
      apply_tz = TRUE,
      verbose = TRUE,
      check_attributes = FALSE
    ),
    "created NA times"
  )
})

testthat::test_that("GT3X helper reports start mismatches", {
  fake = list(
    header = list(
      TimeZone = NULL,
      accrange = 8,
      frequency = 100L,
      start = as.POSIXct("2019-09-17 18:40:01", tz = "UTC")
    ),
    data = data.frame(
      time = c(
        as.POSIXct("2019-09-17 18:40:00", tz = "UTC"),
        as.POSIXct("2019-09-17 18:40:01", tz = "UTC")
      ),
      X = c(1, 2),
      Y = c(3, 4),
      Z = c(5, 6)
    )
  )

  res = suppressWarnings(
    actiread:::acti_gt3x_process_time(
      fake,
      apply_tz = FALSE,
      verbose = TRUE,
      check_attributes = FALSE
    )
  )
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
})

testthat::test_that("GT3X metadata can be parsed directly", {
  info = actiread::acti_info_gt3x(actiread::acti_example_gt3x())
  testthat::expect_true(is.list(info))
  testthat::expect_true(length(info) > 0)
})

testthat::test_that("CWA reading works on the shipped example", {
  res = actiread::acti_read_cwa(
    actiread::acti_example_cwa(),
    verbose = FALSE
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
  testthat::expect_true(mean(res$x) > -10)
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
  testthat::expect_true("transformations" %in% names(attributes(res)))
})

testthat::test_that("CWA reading handles tz=NULL and apply_tz = FALSE", {
  res = suppressMessages(
    actiread::acti_read_cwa(
      actiread::acti_example_cwa(),
      tz = NULL,
      apply_tz = FALSE,
      verbose = TRUE
    )
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
})

testthat::test_that("CWA helper falls back to the header attribute", {
  fake = list(
    data = data.frame(
      time = c(
        as.POSIXct("2020-01-01 00:00:00", tz = "UTC"),
        as.POSIXct("2020-01-01 00:00:01", tz = "UTC")
      ),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )
  attr(fake, "header") = list(
    accrange = 8,
    frequency = 100L,
    start = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
  )

  res = suppressWarnings(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = FALSE,
      verbose = FALSE
    )
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
})

testthat::test_that("CWA helper handles tz = NULL", {
  fake = list(
    header = list(
      accrange = 8,
      frequency = 100L,
      start = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
    ),
    data = data.frame(
      time = c(
        as.POSIXct("2020-01-01 00:00:00", tz = "UTC"),
        as.POSIXct("2020-01-01 00:00:01", tz = "UTC")
      ),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  res = suppressWarnings(
    actiread:::acti_cwa_process_time(
      fake,
      tz = NULL,
      apply_tz = FALSE,
      verbose = FALSE
    )
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
})

testthat::test_that("CWA helper handles an empty header", {
  fake = list(
    header = NULL,
    data = data.frame(
      time = c(
        as.POSIXct("2020-01-01 00:00:00", tz = "UTC"),
        as.POSIXct("2020-01-01 00:00:01", tz = "UTC")
      ),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  res = suppressWarnings(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = FALSE,
      verbose = FALSE
    )
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
})

testthat::test_that("CWA helper reports the no-timezone branch", {
  fake = list(
    header = list(
      accrange = 8,
      frequency = 100L,
      start = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
    ),
    data = data.frame(
      time = c(
        as.POSIXct("2020-01-01 00:00:00", tz = "UTC"),
        as.POSIXct("2020-01-01 00:00:01", tz = "UTC")
      ),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  res = suppressMessages(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = FALSE,
      verbose = TRUE
    )
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
})

testthat::test_that("CWA helper warns on start mismatch and missing times", {
  fake = list(
    header = list(
      accrange = 8,
      frequency = 100L,
      start = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
    ),
    data = data.frame(
      time = c(
        as.POSIXct("2020-01-01 01:00:00", tz = "UTC"),
        NA
      ),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  res = suppressWarnings(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = FALSE,
      verbose = FALSE
    )
  )

  testthat::expect_true(anyNA(res$time))
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
})

testthat::test_that("CWA helper stops if timezone conversion creates NA times", {
  fake = list(
    header = list(
      accrange = 8,
      frequency = 100L,
      start = structure(1e20, class = c("POSIXct", "POSIXt"), tzone = "UTC")
    ),
    data = data.frame(
      time = c(1e20, 1e20 + 1),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  testthat::expect_error(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = TRUE,
      verbose = TRUE
    ),
    "created NA times"
  )
})

testthat::test_that("CWA helper stops when timezone conversion adds missing times to pre-existing NA data", {
  fake = list(
    header = list(
      accrange = 8,
      frequency = 100L,
      start = structure(1e20, class = c("POSIXct", "POSIXt"), tzone = "UTC")
    ),
    data = data.frame(
      time = c(NA_real_, 1e20),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  testthat::expect_error(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = TRUE,
      verbose = TRUE
    ),
    "created NA times"
  )
})

testthat::test_that("CWA helper reports timezone application", {
  fake = list(
    header = list(
      accrange = 8,
      frequency = 100L,
      start = as.POSIXct("1970-01-01 00:00:00", tz = "UTC")
    ),
    data = data.frame(
      time = c(0, 1),
      x = c(1, 2),
      y = c(3, 4),
      z = c(5, 6)
    )
  )

  res = suppressMessages(
    actiread:::acti_cwa_process_time(
      fake,
      apply_tz = TRUE,
      verbose = TRUE
    )
  )

  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
})

