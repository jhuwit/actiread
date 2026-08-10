testthat::test_that("acti_py_read_cwa verifies Python dependencies before reading", {
  testthat::skip_if_not_installed("reticulate")
  testthat::skip_if_not_installed("arrow")

  py_available = tryCatch(
    reticulate::py_available(initialize = FALSE),
    error = function(e) FALSE
  )
  testthat::skip_if_not(
    py_available,
    message = "Python is not available for reticulate"
  )

  has_actipy = tryCatch(
    reticulate::py_module_available("actipy"),
    error = function(e) FALSE
  )
  testthat::skip_if_not(
    has_actipy,
    message = "Python module 'actipy' is not available"
  )

  has_pyarrow = tryCatch(
    reticulate::py_module_available("pyarrow"),
    error = function(e) FALSE
  )
  testthat::skip_if_not(
    has_pyarrow,
    message = "Python module 'pyarrow' is not available"
  )

  actipy = reticulate::import("actipy", convert = FALSE)
  pyarrow = reticulate::import("pyarrow", convert = FALSE)

  testthat::expect_false(is.null(actipy))
  testthat::expect_false(is.null(pyarrow))

  res = actiread::acti_py_read_cwa(
    actiread::acti_example_cwa(),
    verbose = FALSE
  )

  testthat::expect_s3_class(res, "tbl_df")
  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(res)))
  testthat::expect_gt(nrow(res), 0L)
  testthat::expect_false(anyNA(res$time))
  testthat::expect_true(is.numeric(attr(res, "sample_rate")))
  testthat::expect_gt(attr(res, "sample_rate"), 0)
  testthat::expect_true("transformations" %in% names(attributes(res)))
  testthat::expect_match(
    paste(attr(res, "transformations"), collapse = " "),
    "acti_py_read_cwa:data_read_via_actipy_read_device"
  )

  header = attr(res, "header")
  testthat::expect_type(header, "list")
  testthat::expect_true(length(header) > 0L)
  testthat::expect_true(any(c("SampleRate", "ResampleRate") %in% names(header)))
})
