#' Decompress an Activity-data File
#'
#' Decompresses `.bz2`, `.gz`, and `.xz` files to a temporary file. If
#' `extension` is `NULL`, the destination extension is inferred after removing
#' the compression extension from `path`.
#'
#' @param path Path to an activity-data file, optionally compressed.
#' @param extension Output file extension. Defaults to `NULL`, which infers the
#'   extension from `path` after removing its compression extension.
#'
#' @returns A list with `path`, the usable file path, and `temporary`, which is
#'   `TRUE` when a temporary decompressed file was created. Callers should
#'   delete `path` when `temporary` is `TRUE`.
#' @export
#'
#' @examples
#' file = acti_decompress_file(acti_example_cwa())
#' if (file$temporary) {
#'   unlink(file$path)
#' }
acti_decompress_file = function(path, extension = NULL) {
  stopifnot(is.character(path), length(path) == 1L,
            is.null(extension) || (is.character(extension) &&
              length(extension) == 1L))
  path = path.expand(path)
  compression_pattern = "\\.(bz2|gz|xz)$"
  if (is.null(extension)) {
    extension = tools::file_ext(sub(compression_pattern, "", path,
                                    ignore.case = TRUE))
  }
  extension = paste0(".", sub("^\\.", "", extension))

  for (compression in c("bz2", "gz", "xz")) {
    if (R.utils::isCompressedFile(
      path,
      method = "extension",
      ext = compression,
      fileClass = ""
    )) {
      connection = switch(compression,
        gz = gzfile,
        xz = xzfile,
        bz2 = bzfile
      )
      return(list(
        path = R.utils::decompressFile(
          path,
          destname = tempfile(fileext = extension),
          temporary = TRUE,
          overwrite = TRUE,
          ext = compression,
          FUN = connection,
          remove = FALSE
        ),
        temporary = TRUE
      ))
    }
  }

  list(path = path, temporary = FALSE)
}
