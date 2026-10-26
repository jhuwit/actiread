testthat::test_that("acti_read guesses supported formats and compressed extensions", {
  testthat::expect_equal(actiread:::acti_guess_reader("activity.cwa"), "acti_read_cwa")
  testthat::expect_equal(actiread:::acti_guess_reader("activity.CWA.GZ"), "acti_read_cwa")
  testthat::expect_equal(actiread:::acti_guess_reader("activity.gt3x.gz"), "acti_read_gt3x")
  testthat::expect_equal(actiread:::acti_guess_reader("activity.bin"), "acti_read_geneactiv")
  testthat::expect_true(is.na(actiread:::acti_guess_reader("sensor.csv")))
  testthat::expect_true(is.na(actiread:::acti_guess_reader("sensor.zip")))
})

testthat::test_that("acti_read reports its selected reader and forwards arguments", {
  args = list(
    actiread::acti_example_gt3x(),
    verbose = TRUE,
    fill_zeroes = FALSE,
    digits = 3L
  )
  if (!actiread:::gt3x_supports_digits()) {
    args$digits = NULL
  }
  testthat::expect_message(
    res <- do.call(actiread::acti_read, args),
    "Using acti_read_gt3x"
  )
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_error(actiread::acti_read("sensor.csv"), "Cannot guess a reader")
})

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
  # Etc/GMT zones use the inverted sign convention
  testthat::expect_equal(actiread:::tzoffset_to_tz("-05:00"), "Etc/GMT+5")
  testthat::expect_equal(actiread:::tzoffset_to_tz("+01:00"), "Etc/GMT-1")
  testthat::expect_equal(actiread:::tzoffset_to_tz("-04:00:00"), "Etc/GMT+4")
  testthat::expect_equal(actiread:::tzoffset_to_tz("+13:00"), "Etc/GMT-13")
  testthat::expect_error(actiread:::tzoffset_to_tz("+05:30"), "whole hours")
  testthat::expect_error(actiread:::tzoffset_to_tz("EST"), "must look like")
  # the zone is the correct number of hours from UTC
  x = as.POSIXct("2020-01-01 12:00:00", tz = "UTC")
  testthat::expect_equal(
    format(x, tz = actiread:::tzoffset_to_tz("-05:00")), "2020-01-01 07:00:00")
  testthat::expect_equal(
    actiread:::tzoffset_to_seconds(c("+05:30", "-04:00:00", "+00:00")),
    c(19800, -14400, 0))
})

testthat::test_that("GT3X reading works on the shipped example", {
  args = list(
    actiread::acti_example_gt3x(),
    verbose = FALSE,
    fill_zeroes = FALSE,
    digits = 3L
  )
  if (!actiread:::gt3x_supports_digits()) {
    args$digits = NULL
  }
  res = do.call(actiread::acti_read_gt3x, args = args)

  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  testthat::expect_equal(mean(res$X), -0.0742151351351352)
  testthat::expect_equal(attr(res, "sample_rate"), 100L)
  testthat::expect_true("transformations" %in% names(attributes(res)))
})


testthat::test_that("GT3X reading works with digits=5L", {
  testthat::skip_if_not(actiread:::gt3x_supports_digits(),
                        "read.gt3x does not support digits")
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

testthat::test_that("fast CWA header reads the shipped example", {
  path = actiread::acti_example_cwa()
  file = actiread::acti_decompress_file(path, extension = ".cwa")
  on.exit(unlink(file$path), add = TRUE)
  header = actiread:::.acti_read_cwa_header_fast(file$path)
  testthat::expect_true(all(c("frequency", "start", "sample_rate") %in%
                            names(header)))
  testthat::expect_equal(header$sample_rate, 100)
})

testthat::test_that("acti_decompress_file infers or accepts an extension", {
  path = actiread::acti_example_cwa()
  inferred = actiread::acti_decompress_file(path)
  on.exit(unlink(inferred$path), add = TRUE)
  testthat::expect_true(inferred$temporary)
  testthat::expect_match(inferred$path, "\\.cwa$")

  explicit = actiread::acti_decompress_file(path, extension = ".bin")
  on.exit(unlink(explicit$path), add = TRUE)
  testthat::expect_match(explicit$path, "\\.bin$")
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

testthat::test_that("acti_read_cwa_header matches the full read's header", {
  header = actiread::acti_read_cwa_header(actiread::acti_example_cwa())
  testthat::expect_type(header, "list")
  testthat::expect_equal(header$sample_rate, 100)
  testthat::expect_equal(header$device, "Axivity")
  testthat::expect_equal(header$acceleration_min, -8)
  testthat::expect_equal(header$acceleration_max, 8)
  testthat::expect_type(header$acceleration_min, "double")

  native = actiread:::.read_cwa(actiread::acti_example_cwa(),
                                start = 0, end = 0)
  native = actiread:::acti_process_header(native)
  testthat::expect_setequal(names(header), names(native))
  for (field in names(native)) {
    testthat::expect_equal(header[[field]], native[[field]],
                           ignore_attr = TRUE, label = field)
  }
})

testthat::test_that("fast CWA header decodes timestamps after 2032", {
  file = actiread::acti_decompress_file(actiread::acti_example_cwa())
  on.exit(unlink(file$path), add = TRUE)
  bytes = readBin(file$path, raw(), file.info(file$path)$size)
  # rewrite the first data block's packed timestamp as 2035-06-15 12:34:56
  timestamp = (35 * 2^26) + (6 * 2^22) + (15 * 2^17) + (12 * 2^12) +
    (34 * 2^6) + 56
  ts_bytes = as.raw(c(timestamp %% 256, (timestamp %/% 256) %% 256,
                      (timestamp %/% 2^16) %% 256, (timestamp %/% 2^24) %% 256))
  block = 1024 + 1:512
  bytes[1024 + 15:18] = ts_bytes
  # disable the checksum so the edited block is still valid
  bytes[1024 + 25] = as.raw(0)
  edited = tempfile(fileext = ".cwa")
  on.exit(unlink(edited), add = TRUE)
  writeBin(bytes, edited)
  header = actiread:::.acti_read_cwa_header_fast(edited)
  testthat::expect_equal(format(header$start, "%Y-%m-%d %H:%M"),
                         "2035-06-15 12:34")
})

testthat::test_that("CWA start/end subset the data", {
  full = actiread::acti_read_cwa(actiread::acti_example_cwa(),
                                 verbose = FALSE)
  part = suppressWarnings(actiread::acti_read_cwa(
    actiread::acti_example_cwa(), start = 1, end = 10, verbose = FALSE))
  testthat::expect_gt(nrow(part), 0)
  testthat::expect_lt(nrow(part), nrow(full))
})

testthat::test_that("CWA and GT3X helpers handle zero rows and NA first times", {
  header = list(frequency = 100L,
                start = as.POSIXct("2020-01-01", tz = "UTC"))
  empty = data.frame(time = numeric(0), x = numeric(0), y = numeric(0),
                     z = numeric(0))
  res = actiread:::acti_cwa_process_time(
    list(header = header, data = empty), apply_tz = FALSE, verbose = FALSE)
  testthat::expect_equal(nrow(res), 0L)

  na_first = data.frame(time = c(NA, 1), x = 1:2, y = 1:2, z = 1:2)
  testthat::expect_warning(
    res <- actiread:::acti_cwa_process_time(
      list(header = header, data = na_first), apply_tz = FALSE,
      verbose = FALSE),
    "missing times"
  )
  testthat::expect_true(is.na(res$time[1]))

  gt3x_empty = data.frame(
    time = as.POSIXct(character(0), tz = "GMT"),
    X = numeric(0), Y = numeric(0), Z = numeric(0))
  res = actiread:::acti_gt3x_process_time(
    list(header = header, data = gt3x_empty), apply_tz = FALSE,
    verbose = FALSE)
  testthat::expect_equal(nrow(res), 0L)

  gt3x_na = data.frame(
    time = as.POSIXct(c(NA, "2020-01-01"), tz = "GMT"),
    X = 1:2, Y = 1:2, Z = 1:2)
  res = suppressWarnings(actiread:::acti_gt3x_process_time(
    list(header = header, data = gt3x_na), apply_tz = FALSE,
    verbose = FALSE))
  testthat::expect_true(is.na(res$time[1]))
})

testthat::test_that("header start mismatch warns", {
  header = list(start = as.POSIXct("2020-01-01", tz = "UTC"))
  testthat::expect_warning(
    actiread:::warn_header_start_mismatch(
      header, as.POSIXct("2020-01-02", tz = "UTC")),
    "Header start date")
  testthat::expect_false(actiread:::warn_header_start_mismatch(
    header, as.POSIXct("2020-01-01", tz = "UTC")))
  testthat::expect_false(actiread:::warn_header_start_mismatch(list(), 1))
})

testthat::test_that("GT3X ignores digits when read.gt3x does not support it", {
  testthat::local_mocked_bindings(gt3x_supports_digits = function() FALSE)
  testthat::expect_warning(
    res <- actiread::acti_read_gt3x(
      actiread::acti_example_gt3x(),
      verbose = FALSE,
      fill_zeroes = FALSE,
      digits = 5L
    ),
    "requires read.gt3x"
  )
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  # the default of 3 matches old read.gt3x, so no warning
  testthat::expect_no_warning(
    actiread::acti_read_gt3x(
      actiread::acti_example_gt3x(),
      verbose = FALSE,
      fill_zeroes = FALSE
    ),
    message = "requires read.gt3x"
  )
})

testthat::test_that("GT3X defaults to 3 digits and digits = NULL uses read.gt3x", {
  res = actiread::acti_read_gt3x(
    actiread::acti_example_gt3x(),
    verbose = FALSE,
    fill_zeroes = FALSE
  )
  testthat::expect_equal(mean(res$X), -0.0742151351351352)
  testthat::expect_equal(res$X, round(res$X, 3))
  res_null = actiread::acti_read_gt3x(
    actiread::acti_example_gt3x(),
    verbose = FALSE,
    fill_zeroes = FALSE,
    digits = NULL
  )
  testthat::expect_equal(res_null$X, res$X)
  testthat::expect_error(
    actiread::acti_read_gt3x(actiread::acti_example_gt3x(), digits = -1),
    "digits"
  )
})
