test_that("csv helper reports and returns parsed data", {
  valid_file <- tempfile(fileext = ".csv")
  writeLines(c("a,b", "1,2"), valid_file)
  parsed <- read_csv_safe(valid_file, show_col_types = FALSE)
  expect_equal(nrow(parsed), 1L)
  expect_equal(names(parsed), c("a", "b"))

  bad_header_file <- tempfile(fileext = ".csv")
  writeLines(c("a,b", "1,2", "3,bad"), bad_header_file)
  expect_error(
    suppressMessages(suppressWarnings(read_csv_safe(
      bad_header_file,
      col_types = readr::cols(a = readr::col_double(), b = readr::col_double()),
      show_col_types = FALSE
    )))
  )

  bad_no_header_file <- tempfile(fileext = ".csv")
  writeLines(c("1,2", "3,bad"), bad_no_header_file)
  expect_error(
    suppressMessages(suppressWarnings(read_csv_safe(
      bad_no_header_file,
      col_names = FALSE,
      col_types = readr::cols(.default = readr::col_double()),
      show_col_types = FALSE
    )))
  )
})

test_that("csv helper reports the bad rows, with and without headers", {
  header_file <- tempfile(fileext = ".csv")
  writeLines(c("a,b", "1,2", "3,4", "5,bad"), header_file)
  msgs <- character(0)
  expect_error(
    withCallingHandlers(
      suppressWarnings(read_csv_safe(
        header_file,
        col_types = readr::cols(a = readr::col_double(),
                                b = readr::col_double()),
        show_col_types = FALSE
      )),
      message = function(m) {
        msgs <<- c(msgs, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    "parsing failure"
  )
  expect_true(any(grepl("Bad Data", msgs)))
  expect_true(any(grepl("bad", msgs)))

  # character col_names means there is no header line
  no_header_file <- tempfile(fileext = ".csv")
  writeLines(c("1,2", "3,bad"), no_header_file)
  expect_error(
    suppressMessages(suppressWarnings(read_csv_safe(
      no_header_file,
      col_names = c("a", "b"),
      col_types = "dd",
      show_col_types = FALSE
    ))),
    "parsing failure"
  )
  ok <- read_csv_safe(no_header_file, col_names = c("a", "b"),
                      col_types = "dc", show_col_types = FALSE)
  expect_equal(names(ok), c("a", "b"))
  expect_equal(nrow(ok), 2L)
})
