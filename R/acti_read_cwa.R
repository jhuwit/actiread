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
#' @param end where to end in the file, passed to [GGIRread::readAxivity]
#' @param tz time zone for the data `time`, passed to `desiredtz` argument in
#' [GGIRread::readAxivity].  If NULL or `""`, no time conversion is done.
#' @param apply_tz turn the `time` column into a `POSIXct` and apply the
#' timezone
#' @param ... additional arguments to pass to [GGIRread::readAxivity()]
#' @param verbose print diagnostic messages, higher values = more verbosity.
#' @returns A `tibble` with attributes of a header, sample rate, and
#' transformations
#' @export
#'
#' @examples
#' data = acti_read_cwa(acti_example_cwa())
#' data = acti_read_cwa(
#'   acti_example_cwa(),
#'   tz = NULL,
#'   apply_tz = FALSE,
#'   verbose = FALSE
#' )
acti_read_cwa = function(
    path,
    start = 0,
    end = Inf,
    tz = "UTC",
    ...,
    apply_tz = TRUE,
    verbose = TRUE
) {
  tz_read = tz
  if (is.null(tz_read)) {
    tz_read = ""
  }
  args = list(
    path,
    start = start,
    end = end,
    tz = tz_read,
    ...
  )
  if (verbose && !"progressBar" %in% names(args)) {
    args$progressBar = TRUE
  }
  data = do.call(.read_cwa, args = args)
  acti_cwa_process_time(
    data = data,
    tz = tz,
    apply_tz = apply_tz,
    verbose = verbose
  )
}


.acti_cwa_count_formatted_na = function(
    time,
    tz,
    chunk_size = 1e5
) {
  if (length(time) == 0) {
    return(0L)
  }

  na_count = 0L
  starts = seq.int(1L, length(time), by = chunk_size)
  for (start in starts) {
    end = min(start + chunk_size - 1L, length(time))
    na_count = na_count + sum(is.na(format(time[start:end], tz = tz)))
  }

  na_count
}


# Internal helper used by acti_read_cwa()
acti_cwa_process_time = function(
    data,
    tz = "UTC",
    apply_tz = TRUE,
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
  data = data %>%
    dplyr::as_tibble()
  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  data = set_transformations(data,
                             "acti_read_cwa:data_read_via_readAxivity",
                             add = TRUE)

  time_na_count = sum(is.na(data$time))
  if (apply_tz) {
    if (tz != "") {
      data$time = as.POSIXct(data$time, origin = "1970-01-01",
                             tz = tz)
      data = set_transformations(data,
                                 "acti_read_cwa:converted_timestamp_to_time",
                                 add = TRUE)
    }
    if (verbose) {
      cli::cli_alert_info("Timezone applied to data")
    }
    formatted_na_count = .acti_cwa_count_formatted_na(data$time, tz = tz)
    if (formatted_na_count > time_na_count) {
      stop("Applying timezone from offset created NA times - stopping.")
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
    warning("Some missing times in cwa data - please check.")
  }

  data = tibble::as_tibble(data)
  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  data
}
