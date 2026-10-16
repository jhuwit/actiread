.read_genea_bin = function(
    path,
    start = 0,
    end = Inf
) {
  check_file_exists(path)
  file = acti_decompress_file(path, extension = ".bin")
  if (file$temporary) {
    on.exit(unlink(file$path), add = TRUE)
  }
  data = GGIRread::readGenea(
    filename = file$path,
    start = start,
    end = end
  )
  header = as.list(data$header[, "hvalues"])
  names(header) = data$header[, "hnames"]
  header = header[!is.na(names(header)) & nzchar(names(header))]
  header$sample_rate = as.numeric(sub("\\s*Hz\\s*$", "",
                                      header$Sample_Rate,
                                      ignore.case = TRUE))
  # Original Genea devices have a fixed +/- 6g range
  header$acceleration_min = -6
  header$acceleration_max = 6
  header$acceleration_units = "g"
  header$battery_voltage = data$batt.voltage
  list(data = data, header = header)
}

#' Read Genea Binary File
#'
#' Reads binary files from the original 'Genea' accelerometer (Unilever
#' Discover, UK) using [GGIRread::readGenea()].  These are not 'GENEActiv'
#' files, see [acti_read_geneactiv()] for those.
#'
#' @param path Path to Genea binary file, optionally compressed.
#' @param start where to start in the file (page number or timestamp), passed
#' to [GGIRread::readGenea]
#' @param end where to end in the file (page number or timestamp), passed to
#' [GGIRread::readGenea].  `Inf` reads to the end of the file.
#' @param tz time zone of the device clock.  The clock time recorded by the
#' device is interpreted as being in `tz`.  If `NULL` or `""`, `UTC` is used.
#' @param apply_tz turn the `time` column into a `POSIXct` in time zone `tz`.
#' If `FALSE`, `time` is left as seconds since 1970-01-01 (device clock time).
#' @param ... not used
#' @param verbose print diagnostic messages
#'
#' @returns A `tibble` with columns `time`, `X`, `Y`, `Z` (in g) and
#' attributes of a header, sample rate, and transformations
#' @export
#'
#' @examples
#' data = acti_read_genea(acti_example_genea())
#' header = acti_read_genea_header(acti_example_genea())
acti_read_genea = function(
    path,
    start = 0,
    end = Inf,
    tz = "UTC",
    ...,
    apply_tz = TRUE,
    verbose = TRUE
) {
  if (is.null(tz) || !nzchar(tz)) {
    tz = "UTC"
  }
  assertthat::assert_that(assertthat::is.string(tz))
  res = .read_genea_bin(path, start = start, end = end)
  header = res$header
  xyz = res$data$rawxyz
  time = as.numeric(res$data$timestamps1)
  if (apply_tz) {
    # device clock time is stored as if it were UTC
    time = as.POSIXct(time, origin = "1970-01-01", tz = "UTC")
    time = lubridate::force_tz(time, tzone = tz)
  }
  data = tibble::tibble(
    time = time,
    # rawxyz is in milli-g
    X = xyz[, 1] / 1000,
    Y = xyz[, 2] / 1000,
    Z = xyz[, 3] / 1000
  )
  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  data = actibase::set_transformations(
    data,
    "acti_read_genea:data_read_via_readGenea",
    add = TRUE)
  if (verbose) {
    cli::cli_alert_success("Read {nrow(data)} rows from Genea file")
  }
  data
}

#' @export
#' @rdname acti_read_genea
acti_read_genea_header = function(path) {
  .read_genea_bin(path, start = 0, end = 1)$header
}
