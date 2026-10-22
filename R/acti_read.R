#' Read an actigraphy or sensor file
#'
#' Guess the appropriate reader from the file extension and pass additional
#' arguments through to that reader. Compressed `.gz`, `.bz2`, and `.xz` files
#' are dispatched by their underlying extension.  Because 'GENEActiv',
#' 'Genea', and 'Parmay Matrix' devices all write `.bin` files, the first
#' kilobyte of `.bin` files (and files with an unknown extension) is inspected
#' to pick the reader.
#'
#' @param path Path to a file to read.
#' @param ... Arguments passed to the selected reader.
#' @param verbose Print the selected reader before reading. Defaults to `TRUE`.
#' @returns The result from the selected reader.
#' @export
#' @examples
#' data = acti_read(acti_example_cwa(), verbose = FALSE)
#' data = acti_read(acti_example_genea(), verbose = FALSE)
acti_read = function(path, ..., verbose = TRUE) {
  if (length(path) != 1L || !is.character(path) || is.na(path)) {
    stop("`path` must be a single, non-missing file path.", call. = FALSE)
  }

  reader_name = acti_guess_reader(path)
  if (is.na(reader_name)) {
    extension = acti_file_extension(path)
    if (file.exists(path) && identical(extension, "bin")) {
      stop("Cannot recognise the device that wrote '", path,
           "' (not GENEActiv, Genea, or Matrix).", call. = FALSE)
    }
    stop("Cannot guess a reader for file extension '.", extension, "'.",
         call. = FALSE)
  }
  check_file_exists(path)

  if (isTRUE(verbose)) {
    message("Using ", reader_name, " to read ", path)
  }
  reader = get(reader_name, mode = "function", inherits = TRUE)
  reader(path, ..., verbose = verbose)
}

# Lower-case extension after removing any compression extension
acti_file_extension = function(file) {
  filename = tolower(basename(file))
  filename = sub("[.](gz|bz2|xz)$", "", filename)
  tools::file_ext(filename)
}

acti_guess_reader = function(file) {
  extension = acti_file_extension(file)
  reader = switch(
    extension,
    cwa = "acti_read_cwa",
    gt3x = "acti_read_gt3x",
    NA_character_
  )
  if (!is.na(reader)) {
    return(reader)
  }
  sniffed = acti_sniff_reader(file)
  if (is.na(sniffed) && identical(extension, "bin") && !file.exists(file)) {
    # nothing to inspect, so fall back to the most common .bin device
    sniffed = "acti_read_geneactiv"
  }
  sniffed
}

# Inspect the first kilobyte of a file to identify the device.  gzfile()
# transparently reads uncompressed, gzip, bzip2, and xz files, so this does
# not decompress the whole file.
acti_sniff_reader = function(file) {
  if (!file.exists(file)) {
    return(NA_character_)
  }
  con = gzfile(file, "rb")
  on.exit(close(con), add = TRUE)
  bytes = tryCatch(readBin(con, raw(), n = 1024L),
                   error = function(e) raw(0))
  if (length(bytes) == 0) {
    return(NA_character_)
  }
  has_bytes = function(x, at) {
    x = charToRaw(x)
    idx = at + seq_along(x) - 1L
    length(bytes) >= max(idx) && identical(bytes[idx], x)
  }
  contains = function(x) {
    length(grepRaw(x, bytes[seq_len(min(512L, length(bytes)))],
                   fixed = TRUE)) > 0
  }
  # Genea files start with "GENEA/<version>"
  if (has_bytes("GENEA/", 1L)) {
    return("acti_read_genea")
  }
  # GENEActiv files start with a text header with a "Device Identity" section
  if (contains("Device Identity") || contains("Device Type:GENEA")) {
    return("acti_read_geneactiv")
  }
  # Matrix files have 512 bytes of remarks, then "MDTC"
  if (has_bytes("MDTC", 513L)) {
    return("acti_read_parmay_matrix")
  }
  # CWA metadata blocks start with "MD" and a 1020-byte packet length
  if (has_bytes("MD", 1L) && length(bytes) >= 4L &&
      identical(bytes[3:4], as.raw(c(0xFC, 0x03)))) {
    return("acti_read_cwa")
  }
  NA_character_
}
