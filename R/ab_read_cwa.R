.read_cwa = function(
    path,
    start = 0,
    end = Inf,
    tz = "UTC",
    ...
) {

  for (ext in c("bz2", "gz", "xz")) {
    if (
      R.utils::isCompressedFile(
        path,
        method = "extension",
        ext = ext,
        fileClass = "")
    ) {
      FUN = switch(ext,
                   gz = gzfile,
                   xz = xzfile,
                   bz2 = bzfile
      )
      path = R.utils::decompressFile(
        path,
        destname = tempfile(fileext = ".cwa"),
        temporary = TRUE,
        overwrite = TRUE,
        ext = ext,
        FUN = FUN,
        remove = FALSE)
      on.exit(unlink(path, recursive = TRUE),
              add = TRUE)
      break
    }
  }
  data = GGIRread::readAxivity(
    filename = path,
    start = start,
    end = end,
    desiredtz = tz,
    ...
  )
  data
}


#' Read CWA File
#'
#' @param path Path to cwa file
#' @param start where to start in the file, passed to [GGIRread::readAxivity]
#' @param start where to end in the file, passed to [GGIRread::readAxivity]
#' @param tz time zone for the data `time`, passed to `desiredtz` argument in
#' [GGIRread::readAxivity].  If NULL or `""`, no time conversion is done.
#' @param ... additional arguments to pass to [GGIRread::readAxivity()]
#' @param verbose print diagnostic messages, higher values = more verbosity.
#' @returns A `tibble` with attributes of a header, sample rate, and
#' transformations
#' @export
#'
#' @examples
#' data = acti_read_cwa(acti_example_cwa())
acti_read_cwa = function(
    path,
    start = 0,
    end = Inf,
    tz = "UTC",
    ...,
    apply_tz = TRUE,
    verbose = TRUE
) {
  if (is.null(tz)) {
    tz = ""
  }
  assertthat::assert_that(
    assertthat::is.string(tz)
  )
  data = .read_cwa(
    path,
    start = start,
    end = end,
    tz = tz,
    ...
  )
  header = data$header
  header$acceleration_min = paste0("-", header$accrange)
  header$acceleration_max = as.character(header$accrange)
  header$sample_rate = header$frequency
  data = data$data %>%
    dplyr::as_tibble()
  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  data = set_transformations(data,
                             "acti_read_cwa:data_read_via_readAxivity",
                             add = TRUE)

  any_na_time = anyNA(data$time)
  if (apply_tz) {
    if (verbose) {
      cli::cli_alert_info("Timezone applied to data")
    }
    if (tz != "") {
      data$time = as.POSIXct(data$time, origin = "1970-01-01",
                             tz = tz)
      data = set_transformations(data,
                                 "acti_read_cwa:converted_timestamp_to_time",
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

  time1 = data$time[1]
  if (header$start != time1) {
    msg = paste0("Header start date is not same time as data$time,",
                 " may want to use apply_tz = FALSE.")
    warning(msg)
  }

  any_na_time = anyNA(data$time)
  if (any_na_time) {
    warning("Some missing times in cwa data - please check.")
  }

  data = tibble::as_tibble(data)
  data
}
