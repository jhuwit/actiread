testthat::test_that("GENEActiv reading works on the shipped example", {
  path = actiread::acti_example_geneactiv()

  testthat::expect_true(file.exists(path))
  testthat::expect_match(path, "GENEActiv_testfile\\.bin$")

  res = actiread::acti_read_geneactiv(path, verbose = FALSE)

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_true(
    all(c("time", "X", "Y", "Z", "light", "temperature") %in% names(res))
  )
  testthat::expect_gt(nrow(res), 0)
  testthat::expect_s3_class(res$time, "POSIXct")
  testthat::expect_equal(attr(res, "sample_rate"), 85.7)
  testthat::expect_true("transformations" %in% names(attributes(res)))

  header = attr(res, "header")
  testthat::expect_equal(header$acceleration_range, "-8 to 8")
  testthat::expect_equal(header$acceleration_min, -8)
  testthat::expect_equal(header$acceleration_max, 8)
  testthat::expect_equal(header$acceleration_resolution, 0.0039)
  testthat::expect_equal(header$acceleration_units, "g")
})

testthat::test_that("GENEActiv header can be read from the shipped example", {
  header = actiread::acti_read_geneactiv_header(
    actiread::acti_example_geneactiv()
  )

  testthat::expect_type(header, "list")
  testthat::expect_equal(header$serial_number, "012967")
  testthat::expect_equal(header$sample_rate, 85.7)
  testthat::expect_equal(header$acceleration_range, "-8 to 8")
  testthat::expect_equal(header$acceleration_min, -8)
  testthat::expect_equal(header$acceleration_max, 8)
  testthat::expect_equal(header$acceleration_resolution, 0.0039)
  testthat::expect_equal(header$acceleration_units, "g")
})

testthat::test_that("GENEActiv start/end subset the data", {
  path = actiread::acti_example_geneactiv()
  full = actiread::acti_read_geneactiv(path, verbose = FALSE)
  part = actiread::acti_read_geneactiv(path, start = 1, end = 2,
                                       verbose = FALSE)
  testthat::expect_equal(nrow(part), 600L)
  testthat::expect_lt(nrow(part), nrow(full))
})

testthat::test_that("GENEActiv reads a gzipped .bin file", {
  path = actiread::acti_example_geneactiv()
  gz = tempfile(fileext = ".bin.gz")
  on.exit(unlink(gz), add = TRUE)
  con = gzfile(gz, "wb")
  writeBin(readBin(path, raw(), file.info(path)$size), con)
  close(con)
  res = actiread::acti_read_geneactiv(gz, verbose = FALSE)
  orig = actiread::acti_read_geneactiv(path, verbose = FALSE)
  testthat::expect_equal(res$X, orig$X)
  testthat::expect_equal(actiread::acti_read_geneactiv_header(gz)$sample_rate,
                         85.7)
})

testthat::test_that("GENEActiv header does not read all of the data", {
  path = actiread::acti_example_geneactiv()
  called = list()
  read_bin = actiread:::.read_geneactiv_bin
  testthat::local_mocked_bindings(
    .read_geneactiv_bin = function(path, start, end, ...) {
      called <<- list(start = start, end = end)
      res = read_bin(path, start = start, end = end, ...)
      called$rows <<- nrow(res)
      res
    }
  )
  actiread::acti_read_geneactiv_header(path)
  testthat::expect_equal(called$end, 1L)
  testthat::expect_equal(called$rows, 300L)
})

testthat::test_that("GENEActiv extra header info handles missing fields", {
  path = tempfile(fileext = ".bin")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("Device Identity", "Device Type:GENEActiv"), path)
  info = actiread:::get_additional_geneactiv_header_info(path)
  testthat::expect_true(is.na(info$acceleration_range))
  testthat::expect_true(is.na(info$acceleration_min))
  testthat::expect_true(is.na(info$acceleration_resolution))
})
