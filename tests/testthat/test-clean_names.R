testthat::test_that("clean_names snake-cases names", {
  testthat::expect_equal(
    actiread:::clean_names(c("accelX", "Battery %", "# steps", "1st", "")),
    c("accel_x", "battery_percent", "number_steps", "x1st", "x")
  )
})

testthat::test_that("clean_names suffixes duplicates", {
  testthat::expect_equal(
    actiread:::clean_names(c("a", "A", "a")),
    c("a", "a_2", "a_3")
  )
})

testthat::test_that("clean_names suffixes never collide with existing names", {
  out = actiread:::clean_names(c("a", "A", "a_2"))
  testthat::expect_equal(out, c("a", "a_3", "a_2"))
  testthat::expect_false(anyDuplicated(out) > 0)

  out = actiread:::clean_names(c("x", "x_2", "X", "x_2", "x_3"))
  testthat::expect_false(anyDuplicated(out) > 0)

  df = data.frame(1, 2, 3)
  names(df) = c("a", "A", "a_2")
  df = actiread:::clean_names(df)
  testthat::expect_false(anyDuplicated(names(df)) > 0)
  testthat::expect_no_error(dplyr::select(df, dplyr::everything()))
})

testthat::test_that("sensorlogger reader handles headers that clean to a suffixed name", {
  tfile = tempfile(fileext = ".csv")
  on.exit(unlink(tfile), add = TRUE)
  writeLines(c("time,a,A,a_2", "1000000000,1,2,3"), tfile)
  out = acti_read_sensorlogger_general(tfile, verbose = FALSE)
  testthat::expect_false(anyDuplicated(names(out)) > 0)
  testthat::expect_true(all(c("a", "a_2", "a_3") %in% names(out)))
  testthat::expect_equal(out$a_2, 3)
  testthat::expect_equal(out$a_3, 2)
})
