testthat::test_that("Genea reading works on the shipped example", {
  path = actiread::acti_example_genea()
  testthat::expect_true(file.exists(path))

  res = actiread::acti_read_genea(path, verbose = FALSE)
  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_named(res, c("time", "X", "Y", "Z"))
  testthat::expect_equal(nrow(res), 42529L)
  testthat::expect_s3_class(res$time, "POSIXct")
  testthat::expect_equal(attr(res$time, "tzone"), "UTC")
  testthat::expect_equal(format(res$time[1]), "2010-03-30 12:08:36")
  # values are in g, so a resting device is near 1g
  testthat::expect_lt(max(abs(c(res$X, res$Y, res$Z))), 8)
  testthat::expect_equal(attr(res, "sample_rate"), 80)
  testthat::expect_match(
    paste(attr(res, "transformations"), collapse = " "),
    "acti_read_genea:data_read_via_readGenea")

  header = attr(res, "header")
  testthat::expect_equal(header$Serial_Number, "01275")
  testthat::expect_equal(header$acceleration_min, -6)
  testthat::expect_equal(header$acceleration_max, 6)
})

testthat::test_that("Genea time zones and subsets", {
  path = actiread::acti_example_genea()
  ny = actiread::acti_read_genea(path, tz = "America/New_York",
                                 end = 2, verbose = FALSE)
  testthat::expect_lt(nrow(ny), 42529L)
  testthat::expect_equal(attr(ny$time, "tzone"), "America/New_York")
  # the device clock time is kept, but now in New York
  testthat::expect_equal(format(ny$time[1]), "2010-03-30 12:08:36")

  raw_time = actiread::acti_read_genea(path, end = 2, apply_tz = FALSE,
                                       verbose = FALSE)
  testthat::expect_type(raw_time$time, "double")

  null_tz = actiread::acti_read_genea(path, end = 2, tz = NULL,
                                      verbose = FALSE)
  testthat::expect_equal(attr(null_tz$time, "tzone"), "UTC")
})

testthat::test_that("Genea header only reads the first page", {
  header = actiread::acti_read_genea_header(actiread::acti_example_genea())
  testthat::expect_type(header, "list")
  testthat::expect_equal(header$sample_rate, 80)
  testthat::expect_equal(header$Sample_Rate, "80Hz")
})

testthat::test_that("Matrix reading works on the shipped example", {
  path = actiread::acti_example_parmay_matrix()
  testthat::expect_true(file.exists(path))

  res = actiread::acti_read_parmay_matrix(path, verbose = FALSE)
  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_false(any(c("acc_x", "acc_y", "acc_z") %in% names(res)))
  testthat::expect_equal(nrow(res), 12587L)
  testthat::expect_s3_class(res$time, "POSIXct")
  testthat::expect_equal(format(res$time[1], tz = "UTC"),
                         "2025-01-24 20:41:51")
  testthat::expect_equal(attr(res, "sample_rate"), 12.5)
  testthat::expect_s3_class(attr(res, "qc_log"), "data.frame")

  header = attr(res, "header")
  testthat::expect_equal(header$acceleration_min, -8)
  testthat::expect_equal(header$acceleration_max, 8)
  testthat::expect_s3_class(header$start, "POSIXct")
})

testthat::test_that("Matrix time zones", {
  path = actiread::acti_example_parmay_matrix()
  ny = actiread::acti_read_parmay_matrix(path, tz = "America/New_York",
                                         verbose = FALSE)
  testthat::expect_equal(attr(ny$time, "tzone"), "America/New_York")
  testthat::expect_equal(format(ny$time[1]), "2025-01-24 15:41:51")

  raw_time = actiread::acti_read_parmay_matrix(path, apply_tz = FALSE,
                                               verbose = FALSE)
  testthat::expect_type(raw_time$time, "double")
})

testthat::test_that("Matrix header reads without the data", {
  header = actiread::acti_read_parmay_matrix_header(
    actiread::acti_example_parmay_matrix())
  testthat::expect_equal(header$sample_rate, 12.5)
  testthat::expect_equal(header$acc_dynrange, 8L)
  testthat::expect_equal(header$total_packets, 2L)
  testthat::expect_equal(header$acceleration_min, -8)

  not_matrix = tempfile(fileext = ".bin")
  writeBin(as.raw(rep(0, 600)), not_matrix)
  on.exit(unlink(not_matrix), add = TRUE)
  testthat::expect_error(
    actiread::acti_read_parmay_matrix_header(not_matrix), "MDTC")
  small = tempfile(fileext = ".bin")
  writeBin(as.raw(1:10), small)
  on.exit(unlink(small), add = TRUE)
  testthat::expect_error(
    actiread::acti_read_parmay_matrix_header(small), "too small")
})
