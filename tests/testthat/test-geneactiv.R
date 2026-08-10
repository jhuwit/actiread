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
