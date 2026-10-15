#' Read an actigraphy or sensor file
#'
#' Guess the appropriate reader from the file extension and pass additional
#' arguments through to that reader. Compressed `.gz` files are dispatched by
#' their underlying extension.
#'
#' @param file Path to a file to read.
#' @param ... Arguments passed to the selected reader.
#' @param verbose Print the selected reader before reading. Defaults to `TRUE`.
#' @returns The result from the selected reader.
#' @export
#' @examples
#' \dontrun{
#' data = acti_read("activity.gt3x")
#' }
acti_read = function(file, ..., verbose = TRUE) {
  if (length(file) != 1L || !is.character(file) || is.na(file)) {
    stop("`file` must be a single, non-missing file path.", call. = FALSE)
  }

  reader_name = acti_guess_reader(file)
  if (is.na(reader_name)) {
    filename = tolower(basename(file))
    extension = tools::file_ext(filename)
    if (identical(extension, "gz")) {
      filename = sub("[.]gz$", "", filename)
      extension = tools::file_ext(filename)
    }
    stop("Cannot guess a reader for file extension '.", extension, "'.",
         call. = FALSE)
  }

  if (isTRUE(verbose)) {
    message("Using ", reader_name, " to read ", file)
  }
  reader = get(reader_name, mode = "function", inherits = TRUE)
  reader(file, ..., verbose = verbose)
}

acti_guess_reader = function(file) {
  filename = tolower(basename(file))
  extension = tools::file_ext(filename)
  if (identical(extension, "gz")) {
    filename = sub("[.]gz$", "", filename)
    extension = tools::file_ext(filename)
  }
  switch(
    extension,
    cwa = "acti_read_cwa",
    gt3x = "acti_read_gt3x",
    bin = "acti_read_geneactiv",
    NA_character_
  )
}
