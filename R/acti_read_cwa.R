.read_cwa = function(
    path,
    start = 0,
    end = Inf,
    tz = "UTC",
    ...
) {
  file = acti_decompress_file(path, extension = ".cwa")
  if (file$temporary) {
    on.exit(unlink(file$path), add = TRUE)
  }
  data = GGIRread::readAxivity(
    filename = file$path,
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
  data = actibase::set_transformations(data,
                                       "acti_read_cwa:data_read_via_readAxivity",
                                       add = TRUE)
  data = acti_cwa_process_time(
    data = data,
    tz = tz,
    apply_tz = apply_tz,
    verbose = verbose
  )
  data
}

#' @export
#' @rdname acti_read_cwa
acti_read_cwa_header = function(
    path
) {
  args = list(
    path,
    start = 0L,
    end = 0L
  )
  data = do.call(.read_cwa, args = args)
  header = acti_process_header(data)
  if (is.list(data) && !is.null(data$data)) {
    data = data$data
  }
  if (is.null(header)) {
    header = acti_process_header(data)
  }
  header
}

#' Read an Uncompressed CWA Header Quickly
#'
#' Internal counterpart to acti_read_cwa_header() for callers that already
#' have an uncompressed CWA file. It reads the 1024-byte metadata block and
#' only enough 512-byte data blocks to find the first valid timestamp. This
#' avoids parsing acceleration samples.
#'
#' The CWA offsets, checksum validation, timestamp decoding, and returned
#' fields are an intentionally small adaptation of GGIRread::readAxivity():
#' [timestamp decoder](https://github.com/wadpac/GGIRread/blob/master/R/readAxivity.R#L18-L52),
#' [data-block validation and fields](https://github.com/wadpac/GGIRread/blob/master/R/readAxivity.R#L75-L200),
#' and [header construction](https://github.com/wadpac/GGIRread/blob/master/R/readAxivity.R#L265-L351).
#'
#' @param path Path to an uncompressed CWA file.
#'
#' @returns A CWA header list in the format produced by
#'   GGIRread::readAxivity(), normalized with acti_process_header().
#' @keywords internal
#' @noRd
.acti_read_cwa_header_fast = function(path) {
  # R's readBin() cannot read an unsigned 32-bit integer directly. The CWA
  # timestamp is one, so decode it from two little-endian unsigned words.
  # See GGIRread::readAxivity() line 119 in the link above.
  read_uint32 = function(x) {
    words = readBin(x, integer(), n = 2L, size = 2L, signed = FALSE,
                    endian = "little")
    as.double(words[1]) + 65536 * as.double(words[2])
  }

  # CWA files have two 512-byte metadata blocks; the remainder are data
  # blocks. This mirrors readAxivity() lines 363-364.
  blocks = round(file.info(path)$size / 512) - 2
  con = file(path, "rb")
  on.exit(close(con), add = TRUE)

  # The first 1024 bytes contain the MD header. The selected offsets below
  # are the device ID, sample-rate/range byte, and firmware version.
  # See readAxivity() lines 282-311.
  header_block = readBin(con, raw(), n = 1024L)
  if (length(header_block) != 1024L ||
      readChar(header_block, 2L, useBytes = TRUE) != "MD") {
    stop("Header block is incorrect. First two characters must be MD.")
  }

  hw_type = readBin(header_block[5], integer(), n = 1L, size = 1L,
                    signed = FALSE)
  lower_id = readBin(header_block[6:7], integer(), n = 1L, size = 2L,
                     signed = FALSE, endian = "little")
  upper_id = readBin(header_block[12:13], integer(), n = 1L, size = 2L,
                     signed = FALSE, endian = "little")
  if (upper_id == 65535L) {
    upper_id = 0L
  }
  serial = bitwOr(bitwShiftL(upper_id, 16L), lower_id)
  sample_info = readBin(header_block[37], integer(), n = 1L, size = 1L,
                        signed = FALSE)
  frequency = round(3200 / bitwShiftL(1L, 15L - bitwAnd(sample_info, 15L)))
  accrange = bitwShiftR(16L, bitwShiftR(sample_info, 6L))
  firmware = readBin(header_block[42], integer(), n = 1L, size = 1L,
                     signed = FALSE)

  # The native header includes the first valid block's sample count and
  # timestamp. As in readAxivity(), skip at most 20 corrupt blocks, checking
  # the 16-bit checksum only for modern (non-zero dynamic-range) blocks.
  # See readAxivity() lines 80-100 and 313-335.
  first_block = NULL
  for (i in 0:20) {
    block = readBin(con, raw(), n = 512L)
    if (length(block) != 512L) {
      break
    }
    if (readChar(block, 2L, useBytes = TRUE) != "AX") {
      stop("Packet header is incorrect. First two characters must be AX.")
    }
    if (readBin(block[3:4], integer(), n = 1L, size = 2L, signed = FALSE,
                endian = "little") != 508L) {
      stop("Packet length is incorrect, should always be 508.")
    }
    dynamic_range = readBin(block[25], integer(), n = 1L, size = 1L,
                             signed = FALSE)
    checksum = if (dynamic_range == 0L) 0L else {
      sum(readBin(block, integer(), n = 256L, size = 2L, signed = FALSE,
                  endian = "little")) %% 65536L
    }
    if (checksum == 0L) {
      first_block = block
      break
    }
    warning("Skipping corrupt block #", i)
  }
  if (is.null(first_block)) {
    stop("Error reading file. The first 21 blocks are corrupt.")
  }

  # Recover the block frequency, fractional timestamp, and relative sample
  # shift using the same compatibility rules as readAxivity() lines 169-200.
  dynamic_range = readBin(first_block[25], integer(), n = 1L, size = 1L,
                           signed = FALSE)
  data_frequency = if (dynamic_range == 0L) {
    readBin(first_block[27:28], integer(), n = 1L, size = 2L,
            signed = FALSE, endian = "little")
  } else {
    round(3200 / bitwShiftL(1L, 15L - bitwAnd(dynamic_range, 15L)))
  }
  timestamp_offset = readBin(first_block[5:6], integer(), n = 1L, size = 2L,
                              signed = FALSE, endian = "little")
  shift = readBin(first_block[27:28], integer(), n = 1L, size = 2L,
                  signed = FALSE, endian = "little")
  fraction = 0
  if (dynamic_range != 0L && bitwAnd(timestamp_offset, 32768L) != 0L) {
    fraction = bitwShiftL(bitwAnd(timestamp_offset, 32767L), 1L)
    shift = shift + bitwShiftR(fraction * data_frequency, 16L)
  }
  # Decode the packed calendar timestamp and apply its fraction and shift.
  # This is the first-call branch of readAxivity()'s timestamp decoder
  # (lines 28-52), where there is no preceding timestamp to reconcile.
  timestamp = read_uint32(first_block[15:18])
  coded_minutes = bitwShiftR(timestamp, 6L)
  start = as.POSIXct(
    sprintf("%d-%d-%d %d:%d:%d",
            bitwAnd(bitwShiftR(timestamp, 26L), 63L) + 2000L,
            bitwAnd(bitwShiftR(timestamp, 22L), 15L),
            bitwAnd(bitwShiftR(timestamp, 17L), 31L),
            bitwAnd(bitwShiftR(timestamp, 12L), 31L),
            bitwAnd(coded_minutes, 63L), bitwAnd(timestamp, 63L)),
    tz = "UTC"
  )
  start = as.POSIXct(as.numeric(start) + fraction / 65536 - shift / data_frequency,
                     origin = "1970-01-01", tz = "UTC")
  block_length = readBin(first_block[29:30], integer(), n = 1L, size = 2L,
                          signed = FALSE, endian = "little")

  # Return GGIRread's native header fields, then add the package's normalized
  # acceleration range and sample-rate aliases.
  acti_process_header(list(header = list(
    uniqueSerialCode = serial,
    frequency = frequency,
    start = start,
    device = "Axivity",
    firmwareVersion = firmware,
    blocks = blocks,
    accrange = accrange,
    hardwareType = if (hw_type == 100L) "AX6" else "AX3",
    blockLength = block_length
  )))
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

acti_cwa_apply_tz = function(
    data,
    tz = "UTC",
    apply_tz = TRUE,
    verbose = TRUE) {
  time_na_count = sum(is.na(data$time))
  if (apply_tz) {
    if (tz != "") {
      data$time = as.POSIXct(data$time, origin = "1970-01-01",
                             tz = tz)
      data = actibase::set_transformations(data,
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
  data
}

# Internal helper used by acti_read_cwa()
acti_cwa_process_time = function(
    data,
    tz = "UTC",
    apply_tz = TRUE,
    verbose = TRUE
) {

  transforms = actibase::get_transformations(data)
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

  data = actibase::set_transformations(data, transforms, add = FALSE)

  data = acti_cwa_apply_tz(data,
                           tz = tz,
                           apply_tz = apply_tz,
                           verbose = verbose)

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
