.with_matrix_file = function(path, fun) {
  check_file_exists(path)
  file = acti_decompress_file(path, extension = ".bin")
  if (file$temporary) {
    on.exit(unlink(file$path), add = TRUE)
  }
  fun(file$path)
}

# Read the fixed part of the Matrix header: bytes 513-516 are "MDTC",
# 517-520 the total packets, 521-522 the accelerometer range, and 523-524 the
# gyroscope range.  See the details section of ?GGIRread::readParmayMatrix.
.read_parmay_matrix_header_fast = function(path) {
  con = file(path, "rb")
  on.exit(close(con), add = TRUE)
  raw = readBin(con, raw(), n = 524L)
  if (length(raw) < 524L) {
    stop("File is too small to be a Matrix file.", call. = FALSE)
  }
  magic = raw[513:516]
  if (rawToChar(magic[magic != as.raw(0)]) != "MDTC") {
    stop("Header string is not MDTC, this is not a Matrix file.",
         call. = FALSE)
  }
  remarks = raw[1:512]
  remarks = trimws(rawToChar(remarks[remarks != as.raw(0)]))
  uint = function(x, size) {
    readBin(x, integer(), n = 1L, size = size, signed = size == 4L,
            endian = "little")
  }
  list(
    remarks = remarks,
    total_packets = uint(raw[517:520], 4L),
    acc_dynrange = uint(raw[521:522], 2L),
    gyro_range = uint(raw[523:524], 2L)
  )
}

.finalize_matrix_header = function(header) {
  if (!is.null(header$acc_dynrange)) {
    header$acceleration_min = -as.numeric(header$acc_dynrange)
    header$acceleration_max = as.numeric(header$acc_dynrange)
  }
  if (!is.null(header$sf)) {
    header$sample_rate = header$sf
  }
  if (!is.null(header$starttime)) {
    header$start = header$starttime
  }
  header
}

#' Read Parmay Tech Matrix Binary File
#'
#' Reads `.bin`/`.BIN` files from Parmay Tech Matrix devices using
#' [GGIRread::readParmayMatrix()].
#'
#' @param path Path to Matrix binary file, optionally compressed.
#' @param start index of the first packet to read, passed to
#' [GGIRread::readParmayMatrix]
#' @param end index of the last packet to read, passed to
#' [GGIRread::readParmayMatrix].  `NULL` reads all packets.
#' @param tz time zone for the data `time`, passed to `desiredtz` in
#' [GGIRread::readParmayMatrix].  If `NULL` or `""`, no time conversion is done.
#' @param apply_tz turn the `time` column into a `POSIXct` in time zone `tz`.
#' If `FALSE`, `time` is left as seconds since 1970-01-01.
#' @param ... additional arguments to pass to [GGIRread::readParmayMatrix()],
#' such as `read_gyro`, `read_temp`, or `read_heart`
#' @param verbose print diagnostic messages
#'
#' @returns A `tibble` with columns `time`, `X`, `Y`, `Z` (in g), any other
#' sensors read, and attributes of a header, sample rate, quality-control log
#' (`qc_log`), and transformations
#' @export
#'
#' @examples
#' data = acti_read_parmay_matrix(acti_example_parmay_matrix())
#' header = acti_read_parmay_matrix_header(acti_example_parmay_matrix())
acti_read_parmay_matrix = function(
    path,
    start = 1,
    end = NULL,
    tz = "UTC",
    ...,
    apply_tz = TRUE,
    verbose = TRUE
) {
  if (is.null(tz)) {
    tz = ""
  }
  assertthat::assert_that(assertthat::is.string(tz))
  res = .with_matrix_file(path, function(x) {
    fast = .read_parmay_matrix_header_fast(x)
    out = GGIRread::readParmayMatrix(
      filename = x,
      output = "all",
      start = start,
      end = end,
      desiredtz = tz,
      ...
    )
    out$header = c(out$header, fast[setdiff(names(fast), names(out$header))])
    out
  })
  header = .finalize_matrix_header(res$header)
  data = tibble::as_tibble(res$data)
  cn = colnames(data)
  cn[cn == "acc_x"] = "X"
  cn[cn == "acc_y"] = "Y"
  cn[cn == "acc_z"] = "Z"
  colnames(data) = cn
  if (apply_tz && nrow(data) > 0) {
    data$time = as.POSIXct(data$time, origin = "1970-01-01", tz = tz)
  }
  attr(data, "header") = header
  attr(data, "sample_rate") = header$sample_rate
  attr(data, "qc_log") = res$QClog
  data = actibase::set_transformations(
    data,
    "acti_read_parmay_matrix:data_read_via_readParmayMatrix",
    add = TRUE)
  if (verbose) {
    cli::cli_alert_success("Read {nrow(data)} rows from Matrix file")
  }
  data
}

#' @export
#' @rdname acti_read_parmay_matrix
acti_read_parmay_matrix_header = function(path) {
  header = .with_matrix_file(path, function(x) {
    header = .read_parmay_matrix_header_fast(x)
    header$sf = GGIRread::readParmayMatrix(x, output = "sf")
    header
  })
  .finalize_matrix_header(header)
}
