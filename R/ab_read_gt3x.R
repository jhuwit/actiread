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
#' @param apply_tz Apply the timezone from the header `TimeZone` attribute
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
#' path = system.file("extdata", "TAS1H30182785_2019-09-17.gt3x.gz",
#'                    package = "actibase")
#' ac = acti_read_gt3x(path, verbose = FALSE)
acti_read_gt3x = function(
    path,
    asDataFrame = TRUE,
    imputeZeroes = TRUE,
    verbose = TRUE,
    ...,
    fill_zeroes = TRUE,
    apply_tz = TRUE,
    check_attributes = TRUE,
    tz = "GMT"
) {

  data = read.gt3x::read.gt3x(
    path = path,
    asDataFrame = asDataFrame,
    imputeZeroes = imputeZeroes,
    verbose = verbose > 1,
    ...)
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

  # this puts data in correct timezone (still ends up in UTC)
  hdr = attr(data, "header")
  if (NROW(hdr$TimeZone) == 0 || is.null(hdr$TimeZone)) {
    cli::cli_warn("No header found in gt3x file.")
  } else {
    tz_from_offset = tzoffset_to_tz(hdr$TimeZone)
    if (verbose) {
      cli::cli_alert_info("Timezone from header: {hdr$TimeZone}")
      cli::cli_alert_info("Timezone from offset: {tz_from_offset}")
    }
  }

  any_na_time = anyNA(data$time)
  if (any_na_time) {
    warning("Some missing times in gt3x data - please check.")
  }
  if (apply_tz) {
    # data$time = lubridate::force_tz(
    #   lubridate::with_tz(data$time, tz_from_offset),
    #   "GMT")
    if (verbose) {
      cli::cli_alert_info("Timezone applied to data")
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
  } else {
    if (verbose) {
      cli::cli_alert_info("Timezone not applied to data")
    }
  }
  data = as.data.frame(data)
  if (check_attributes) {
    stopifnot(!is.null(attr(data, "sample_rate")))
  }
  data = tibble::as_tibble(data)
  data
}

#' @export
#' @rdname acti_read_gt3x
acti_info_gt3x = function(
    path,
    ...
) {

  data = read.gt3x::parse_gt3x_info(
    path = path,
    ...)
  data
}
