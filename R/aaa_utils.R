#' Transform timezone offset to timezone
#'
#' @param x A character vector
#'
#' @returns A character vector
#' @export
#'
#' @examples
#' tzoffset_to_tz(c("+00:00", "-05:00", "+01:00"))
tzoffset_to_tz = function(x) {
  stopifnot(all(grepl(":00", x)))
  x = sub(":00:00$", "", x)
  x = sub(":00$", "", x)
  stopifnot(nchar(x) <= 3)
  x = as.numeric(x)
  x = ifelse(x > 0, paste0("+", x), as.character(x))
  x = paste0("Etc/GMT", x)
  stopifnot(x %in% OlsonNames())
  x
}


read_csv_safe = function(..., guess_max = Inf) {
  x = readr::read_csv(..., guess_max = guess_max)
  p = readr::problems(x)
  cn = list(...)$col_names
  if (is.null(cn)) {
    cn = TRUE
  }
  if (nrow(p) > 0) {
    message(paste(utils::capture.output(print(p)), collapse = "\n"))

    rows = unique(p$row)
    if (cn) {
      rows = rows - 1
    }
    bad_data = x[rows, unique(p$col)]
    message("Bad Data:\n")
    message(paste(utils::capture.output(print(bad_data)), collapse = "\n"))
  }
  readr::stop_for_problems(x)
  x
}


