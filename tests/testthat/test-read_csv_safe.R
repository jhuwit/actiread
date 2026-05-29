test_that("csv helper reports and returns parsed data", {
  valid_file <- tempfile(fileext = ".csv")
  writeLines(c("a,b", "1,2"), valid_file)
  parsed <- read_csv_safe(valid_file, show_col_types = FALSE)
  expect_equal(nrow(parsed), 1L)
  expect_equal(names(parsed), c("a", "b"))

  bad_header_file <- tempfile(fileext = ".csv")
  writeLines(c("a,b", "1,2", "3,bad"), bad_header_file)
  expect_error(
    read_csv_safe(
      bad_header_file,
      col_types = readr::cols(a = readr::col_double(), b = readr::col_double()),
      show_col_types = FALSE
    )
  )

  bad_no_header_file <- tempfile(fileext = ".csv")
  writeLines(c("1,2", "3,bad"), bad_no_header_file)
  expect_error(
    read_csv_safe(
      bad_no_header_file,
      col_names = FALSE,
      col_types = readr::cols(.default = readr::col_double()),
      show_col_types = FALSE
    )
  )
})
