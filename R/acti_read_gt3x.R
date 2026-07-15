#' Read GT3X file
#'
#' @param path Path to gt3x file
#' @param asDataFrame convert to an `activity_df`, see
#' \code{as.data.frame.activity}
#' @param imputeZeroes Impute zeros in case there are missingness?
#' Default is `FALSE`, in which case
#' the time series will be incomplete in case there is missingness.
#' @param ... additional arguments to pass to [read.gt3x::read.gt3x()]
#' @param verbose print diagnostic messages, higher values = more verbosity.
#' @param apply_tz Apply the timezone from the header `TimeZone` attribute,
#' if available
#' @param check_attributes Check that the attributes are included This is a sanity check,
#' including checking that `sample_rate` is in the attributes.
#' @param tz timezone to project the data into.  The data read in via
#' [read.gt3x::read.gt3x()] says the timezone is GMT, but the time values is in the
#' native timezone.  So this data is projected into the correct time zone and then
#' forced into the timezone given by `tz`.  Set to `NULL` to not apply this
#' forcing.
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
    fill_zeroes = TRUE,
    apply_tz = FALSE,
    check_attributes = TRUE,
    tz = "GMT"
) {
  args = list(path = path,
              asDataFrame = asDataFrame,
              imputeZeroes = imputeZeroes,
              verbose = verbose > 1,
              ...)
  if (is.null(args$digits) &&
      (
        utils::packageVersion("read.gt3x") >= package_version("1.3.0")  ||
        "digits" %in% methods::formalArgs(read.gt3x::read.gt3x)
      )
  ) {
    args$digits = 5L
  }
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
  if (is.null(tz)) {
    tz = ""
  }
  assertthat::assert_that(
    assertthat::is.string(tz)
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
    if (verbose) {
      cli::cli_alert_info("Timezone applied to data")
    }
    if (NROW(header$TimeZone) == 0 || is.null(header$TimeZone)) {
      cli::cli_warn("No TimeZone found in header data in gt3x.")
    } else {
      tz_from_offset = tzoffset_to_tz(header$TimeZone)
      if (verbose) {
        cli::cli_alert_info("Timezone from header: {header$TimeZone}")
        cli::cli_alert_info("Timezone from offset: {tz_from_offset}")
      }
      data$time = lubridate::with_tz(data$time, tz_from_offset)
      data = set_transformations(data,
                                 paste0("acti_read_gt3x:timezone_", tz_from_offset, "_applied"),
                                 add = TRUE)
      if (!is.null(tz)) {
        data$time = lubridate::force_tz(data$time, tz = tz)
        data = set_transformations(data,
                                   paste0("acti_read_gt3x:timezone_", tz, "_forced"),
                                   add = TRUE)
      }
      if (!any_na_time && anyNA(data$time)) {
        stop("Applying timezone from offset created NA times - stopping.")
      }
    }
  } else if (verbose) {
    cli::cli_alert_info("Timezone not applied to data")
  }

  time1 = data$time[1]
  header_start = header$start
  if (is.null(header_start)) {
    header_start = header$start_time
  }
  if (!is.null(header_start) && length(header_start) > 0 && header_start != time1) {
    msg = paste0("Header start date is not same time as data$time,",
                 " may want to use apply_tz = FALSE.")
    warning(msg)
  }

  any_na_time = anyNA(data$time)
  if (any_na_time) {
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

  data = read.gt3x::parse_gt3x_info(
    path = path,
    ...)
  data
}
