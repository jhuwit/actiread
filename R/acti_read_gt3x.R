#' Read GT3X file
#'
#' @param path Path to gt3x file
#' @param asDataFrame convert to an `activity_df`, see
#' \code{as.data.frame.activity}
#' @param imputeZeroes Impute zeros in case there are missingness?
#' Default is `TRUE`.  If `FALSE`, the time series will be incomplete in case
#' there is missingness.
#' @param ... additional arguments to pass to [read.gt3x::read.gt3x()]
#' @param digits number of digits to round the acceleration values to, passed
#' to [read.gt3x::read.gt3x()] (requires `read.gt3x >= 1.3.0`).  The default
#' `3L` matches both [read.gt3x::read.gt3x()] and ActiLife, so the data
#' agree with ActiLife exports.  Set to `NULL` to use the
#' [read.gt3x::read.gt3x()] default.  If you will resample the data (e.g. to
#' 30 Hz for activity counts), read with `digits` of at least `6L` (e.g.
#' `8L`), resample, and then round to 3 digits: rounding to 3 before
#' resampling loses precision, and rounding values already rounded to 5
#' digits rounds twice (e.g. `0.1234996` to `0.12350` to `0.124`).
#' @param verbose print diagnostic messages, higher values = more verbosity.
#' @param apply_tz Apply the timezone from the header `TimeZone` attribute,
#' if available
#' @param check_attributes Check that the attributes are included This is a sanity check,
#' including checking that `sample_rate` is in the attributes.
#' @param tz timezone to display the data in when `apply_tz = TRUE`.  The
#' data read in via [read.gt3x::read.gt3x()] says the timezone is GMT, but the
#' time values are the device's local clock time.  When `apply_tz = TRUE`, the
#' header `TimeZone` offset is used to recover the true time, which is then
#' shown in `tz` (the default `"GMT"` gives UTC times).  Set to `NULL` to keep
#' the fixed-offset zone from the header (e.g. `"Etc/GMT+4"` for `-04:00`), or
#' UTC if the offset is not a whole number of hours.
#' @param fill_zeroes Rows with all zeros will be filled in with the last
#' observation carried forward as is done with ActiLife.  Recommended
#' @returns A `data.frame`
#' @export
#'
#' @examples
#' library(actiread)
#' data = acti_read_gt3x(acti_example_gt3x())
#' data = acti_read_gt3x(
#'   acti_example_gt3x(),
#'   tz = NULL,
#'   apply_tz = FALSE,
#'   verbose = FALSE,
#'   fill_zeroes = FALSE
#' )
acti_read_gt3x = function(
    path,
    asDataFrame = TRUE,
    imputeZeroes = TRUE,
    verbose = TRUE,
    ...,
    digits = 3L,
    fill_zeroes = TRUE,
    apply_tz = FALSE,
    check_attributes = TRUE,
    tz = "GMT"
) {
  check_file_exists(path)
  file = decompress_non_gz(path, extension = ".gt3x")
  if (file$temporary) {
    on.exit(unlink(file$path), add = TRUE)
  }
  path = file$path
  if (!is.null(digits)) {
    assertthat::assert_that(assertthat::is.count(digits) || digits == 0)
    digits = as.integer(digits)
  }
  # read.gt3x < 1.3.0 always rounds to 3 digits, so only warn if a
  # different number of digits was asked for
  if (!is.null(digits) && !gt3x_supports_digits()) {
    if (digits != 3L) {
      cli::cli_warn(paste0(
        "{.arg digits} requires read.gt3x >= 1.3.0, ",
        "ignoring {.arg digits} = {digits}"))
    }
    digits = NULL
  }
  args = list(path = path,
              asDataFrame = asDataFrame,
              imputeZeroes = imputeZeroes,
              verbose = verbose > 1,
              ...)
  args$digits = digits
  data = do.call(read.gt3x::read.gt3x, args = args)
  data = set_transformations(data,
                             "acti_read_gt3x:data_read",
                             add = TRUE)
  if (fill_zeroes) {
    if (verbose) {
      cli::cli_alert_info("Filling zeros in data")
    }
    data = acti_fill_zeros(data)
    if (verbose) {
      cli::cli_alert_success("Filled zeros in data")
    }
  }
  acti_gt3x_process_time(
    data = data,
    tz = tz,
    apply_tz = apply_tz,
    check_attributes = check_attributes,
    verbose = verbose
  )
}


# Internal helper used by acti_read_gt3x()
acti_gt3x_process_time = function(
    data,
    tz = "GMT",
    apply_tz = TRUE,
    check_attributes = TRUE,
    verbose = TRUE
) {
  if (!is.null(tz) && !nzchar(tz)) {
    tz = NULL
  }
  assertthat::assert_that(
    is.null(tz) || assertthat::is.string(tz)
  )

  header = acti_process_header(data)
  if (is.list(data) && !is.null(data$data)) {
    data = data$data
  }
  if (is.null(header)) {
    header = acti_process_header(data)
  }
  data = dplyr::as_tibble(data)

  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  data = set_transformations(data,
                             "acti_read_gt3x:attributes_set",
                             add = TRUE)

  any_na_time = anyNA(data$time)
  if (any_na_time) {
    warning("Some missing times in gt3x data - please check.")
  }
  if (apply_tz) {
    if (NROW(header$TimeZone) == 0 || is.null(header$TimeZone)) {
      cli::cli_warn("No TimeZone found in header data in gt3x.")
    } else {
      offset = tzoffset_to_seconds(header$TimeZone)
      target_tz = tz
      if (is.null(target_tz)) {
        target_tz = tryCatch(
          tzoffset_to_tz(header$TimeZone),
          error = function(e) {
            if (verbose) {
              cli::cli_alert_info(
                "No fixed-offset time zone for {header$TimeZone}, using UTC")
            }
            "UTC"
          })
      }
      if (verbose) {
        cli::cli_alert_info("Timezone from header: {header$TimeZone}")
        cli::cli_alert_info("Timezone applied to data: {target_tz}")
      }
      # times are local clock time labelled as GMT: remove the offset to get
      # the true instant, then display in the target time zone
      utc_time = lubridate::force_tz(data$time, tzone = "UTC") - offset
      data$time = lubridate::with_tz(utc_time, tzone = target_tz)
      data = set_transformations(
        data,
        paste0("acti_read_gt3x:timezone_offset_", header$TimeZone, "_applied"),
        add = TRUE)
      data = set_transformations(
        data,
        paste0("acti_read_gt3x:timezone_", target_tz, "_displayed"),
        add = TRUE)
      if (!any_na_time && anyNA(data$time)) {
        stop("Applying timezone from offset created NA times - stopping.")
      }
    }
  } else if (verbose) {
    cli::cli_alert_info("Timezone not applied to data")
  }

  warn_header_start_mismatch(header, data$time)

  if (!any_na_time && anyNA(data$time)) {
    warning("Some missing times in gt3x data - please check.")
  }

  data = as.data.frame(data)
  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  if (check_attributes) {
    stopifnot(!is.null(attr(data, "sample_rate")))
  }
  tibble::as_tibble(data)
}



#' @export
#' @rdname acti_read_gt3x
#' @examples
#' info = acti_info_gt3x(acti_example_gt3x())
acti_info_gt3x = function(
    path,
    ...
) {

  check_file_exists(path)
  file = decompress_non_gz(path, extension = ".gt3x")
  if (file$temporary) {
    on.exit(unlink(file$path), add = TRUE)
  }
  path = file$path
  data = read.gt3x::parse_gt3x_info(
    path = path,
    ...)
  data
}


# read.gt3x handles .gz itself, so only decompress .bz2 and .xz files
decompress_non_gz = function(path, extension) {
  if (grepl("[.](bz2|xz)$", path, ignore.case = TRUE)) {
    return(acti_decompress_file(path, extension = extension))
  }
  list(path = path, temporary = FALSE)
}

# read.gt3x 1.3.0 added `digits`, which read.gt3x() passes through `...` to
# parseGT3X(), so check parseGT3X() as well as the version
gt3x_supports_digits = function() {
  utils::packageVersion("read.gt3x") >= package_version("1.3.0") ||
    "digits" %in% names(formals(utils::getFromNamespace("parseGT3X",
                                                        "read.gt3x")))
}
