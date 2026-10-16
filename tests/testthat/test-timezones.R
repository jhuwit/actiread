fake_gt3x <- function(offset, time = "2019-09-17 18:40:00") {
  list(
    header = list(TimeZone = offset, frequency = 100L),
    data = data.frame(
      time = as.POSIXct(time, tz = "GMT"),
      X = 1, Y = 2, Z = 3
    )
  )
}

testthat::test_that("GT3X apply_tz shifts the local clock time to the true time", {
  base = actiread::acti_read_gt3x(actiread::acti_example_gt3x(),
                                  verbose = FALSE, fill_zeroes = FALSE)
  testthat::expect_equal(attr(base, "header")$TimeZone, "-04:00:00")

  utc = actiread::acti_read_gt3x(actiread::acti_example_gt3x(),
                                 verbose = FALSE, fill_zeroes = FALSE,
                                 apply_tz = TRUE)
  # device was at UTC-4, so the true time is 4 hours later in UTC
  testthat::expect_equal(as.numeric(utc$time[1]) - as.numeric(base$time[1]),
                         4 * 3600)
  testthat::expect_equal(format(utc$time[1], tz = "UTC"),
                         "2019-09-17 22:40:00")

  ny = actiread::acti_read_gt3x(actiread::acti_example_gt3x(),
                                verbose = FALSE, fill_zeroes = FALSE,
                                apply_tz = TRUE, tz = "America/New_York")
  testthat::expect_equal(attr(ny$time, "tzone"), "America/New_York")
  testthat::expect_equal(format(ny$time[1]), "2019-09-17 18:40:00")
  testthat::expect_equal(as.numeric(ny$time), as.numeric(utc$time))
})

testthat::test_that("GT3X tz = NULL keeps the header offset, not the system zone", {
  old_tz = Sys.getenv("TZ")
  on.exit(Sys.setenv(TZ = old_tz), add = TRUE)
  Sys.setenv(TZ = "Asia/Tokyo")

  res = suppressMessages(actiread::acti_read_gt3x(
    actiread::acti_example_gt3x(),
    verbose = TRUE, fill_zeroes = FALSE,
    apply_tz = TRUE, tz = NULL
  ))
  testthat::expect_equal(attr(res$time, "tzone"), "Etc/GMT+4")
  testthat::expect_equal(format(res$time[1]), "2019-09-17 18:40:00")
  testthat::expect_equal(format(res$time[1], tz = "UTC"),
                         "2019-09-17 22:40:00")
})

testthat::test_that("GT3X handles half-hour and large offsets", {
  india = actiread:::acti_gt3x_process_time(
    fake_gt3x("+05:30"), tz = "UTC", apply_tz = TRUE, verbose = FALSE,
    check_attributes = FALSE)
  testthat::expect_equal(format(india$time, tz = "UTC"), "2019-09-17 13:10:00")

  # no Etc/GMT zone exists for +05:30, so UTC is used
  msgs = testthat::capture_messages(
    india_null <- actiread:::acti_gt3x_process_time(
      fake_gt3x("+05:30"), tz = NULL, apply_tz = TRUE, verbose = TRUE,
      check_attributes = FALSE)
  )
  testthat::expect_true(any(grepl("using UTC", msgs)))
  testthat::expect_equal(attr(india_null$time, "tzone"), "UTC")
  testthat::expect_equal(format(india_null$time), "2019-09-17 13:10:00")

  kiribati = actiread:::acti_gt3x_process_time(
    fake_gt3x("+14:00"), tz = NULL, apply_tz = TRUE, verbose = FALSE,
    check_attributes = FALSE)
  testthat::expect_equal(attr(kiribati$time, "tzone"), "Etc/GMT-14")
  testthat::expect_equal(format(kiribati$time), "2019-09-17 18:40:00")
})

testthat::test_that("CWA non-UTC time zones", {
  utc = actiread::acti_read_cwa(actiread::acti_example_cwa(), verbose = FALSE)
  ny = actiread::acti_read_cwa(actiread::acti_example_cwa(),
                               tz = "America/New_York", verbose = FALSE)
  testthat::expect_equal(attr(ny$time, "tzone"), "America/New_York")
  testthat::expect_equal(nrow(ny), nrow(utc))
  testthat::expect_equal(format(ny$time[1]), format(utc$time[1]))
})

testthat::test_that("CWA apply_tz with no time zone does not claim to apply it", {
  fake = data.frame(time = c(0, 1), x = 1:2)
  testthat::expect_message(
    res <- actiread:::acti_cwa_apply_tz(fake, tz = NULL, verbose = TRUE),
    "timezone not applied"
  )
  testthat::expect_type(res$time, "double")
  res = actiread:::acti_cwa_apply_tz(fake, tz = "UTC", verbose = FALSE)
  testthat::expect_s3_class(res$time, "POSIXct")
})

testthat::test_that("GENEActiv non-UTC time zones", {
  path = actiread::acti_example_geneactiv()
  utc = actiread::acti_read_geneactiv(path, verbose = FALSE)
  ny = actiread::acti_read_geneactiv(path, tz = "America/New_York",
                                     verbose = FALSE)
  testthat::expect_equal(attr(ny$time, "tzone"), "America/New_York")
  testthat::expect_equal(nrow(ny), nrow(utc))
  testthat::expect_equal(format(ny$time[1]), "2013-05-30 10:12:54")

  raw_time = actiread::acti_read_geneactiv(path, apply_tz = FALSE,
                                           verbose = FALSE)
  testthat::expect_type(raw_time$time, "double")
})
