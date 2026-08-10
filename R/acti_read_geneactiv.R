get_additional_geneactiv_header_info = function(path) {
  suppressWarnings({
    x = readLines(path, n = 100)
  })

  # try to find index positions - so will accommodate multiple lines in the notes sections
  # change when new version of binfile is produced.
  acc_range = x[grep("Accelerometer Range", x, ignore.case = TRUE)]
  acc_range = trimws(acc_range)
  acc_res = x[grep("Accelerometer Resolution", x, ignore.case = TRUE)]
  acc_res = trimws(acc_res)
  acc_units = x[grep("Accelerometer Units", x, ignore.case = TRUE)]
  acc_units = trimws(acc_units)
  strip_colon = function(x) {
    sub(".*:", "", x)
  }
  acc_range = strip_colon(acc_range)
  acc_res = strip_colon(acc_res)
  acc_units = strip_colon(acc_units)
  x_acc_range = acc_range
  if (nchar(acc_range) == 0) {
    acc_range = NA_character_
  }
  acc_range = trimws(strsplit(acc_range, "to", fixed = TRUE)[[1]])
  acc_range = as.numeric(acc_range)
  list(
    acceleration_range = x_acc_range,
    acceleration_min = acc_range[1],
    acceleration_max = acc_range[2],
    acceleration_resolution = as.numeric(acc_res),
    acceleration_units = acc_units
  )

}
.read_geneactiv_bin = function(
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
        destname = tempfile(fileext = ".bin"),
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
  path = path.expand(path)
  add_hdr = get_additional_geneactiv_header_info(path)
  data = GGIRread::readGENEActiv(
    filename = path,
    start = start,
    end = end,
    desiredtz = tz,
    ...
  )
  hdr = data$header
  hdr = c(hdr, add_hdr)
  data = data$data.out
  attr(data, "header") = hdr
  attr(data, "sample_rate") = hdr$SampleRate
  data
}


#' Read GENEActiv Binary File
#'
#' @param path Path to geneactiv binary file
#' @param start where to start in the file, passed to [GGIRread::readGENEActiv]
#' @param end where to end in the file, passed to [GGIRread::readGENEActiv]
#' @param tz time zone for the data `time`, passed to `desiredtz` argument in
#' [GGIRread::readGENEActiv].  If NULL or `""`, no time conversion is done.
#' @param ... additional arguments to pass to [GGIRread::readGENEActiv()]
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
acti_read_geneactiv = function(
    path,
    start = 0,
    end = Inf,
    tz = "UTC",
    ...,
    verbose = TRUE
) {
  time = NULL
  rm(list = c("time"))

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
  if (verbose && !("progress_bar" %in% names(args))) {
    args$progress_bar = TRUE
  }
  data = do.call(.read_geneactiv_bin, args = args)
  data = actibase::set_transformations(
    data,
    "acti_read_geneactiv_bin:data_read_via_readGENEActiv",
    add = TRUE)
  data = tibble::as_tibble(data)
  data = actibase::acti_standardise_data(data, subset_xyz = FALSE)
  data = data |>
    dplyr::mutate(time = as.POSIXct(time, origin = "1970-01-01", tz = tz))

  # May want to do something with hdr$tzone
  # Check against hdr$StarTime or hdr$StartTime:
  # See https://github.com/wadpac/GGIRread/issues/96


  #
  # data = acti_geneactiv_process_time(
  #   data = data,
  #   tz = tz,
  #   apply_tz = apply_tz,
  #   verbose = verbose
  # )
  data
}


#' @export
#' @rdname acti_read_geneactiv
acti_read_geneactiv_header = function(
    path
) {
  args = list(
    path,
    start = 0L,
    end = 0L
  )
  data = do.call(.read_geneactiv_bin, args = args)
  header = acti_process_header(data)
  if (is.list(data) && !is.null(data$data)) {
    data = data$data
  }
  if (is.null(header)) {
    header = acti_process_header(data)
  }
  header
}

