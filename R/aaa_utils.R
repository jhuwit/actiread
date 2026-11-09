#' Transform timezone offset to timezone
#'
#' Converts UTC offsets such as `"-05:00"` (5 hours behind UTC) into the
#' matching fixed-offset Olson time zone.  Note that `Etc/GMT` zones use an
#' inverted sign convention, so `"-05:00"` is `"Etc/GMT+5"`.
#'
#' @param x A character vector of offsets in the form `"+HH:MM"` or
#' `"+HH:MM:SS"`
#'
#' @returns A character vector
#' @export
#'
#' @examples
#' tzoffset_to_tz(c("+00:00", "-05:00", "+01:00"))
tzoffset_to_tz = function(x) {
  seconds = tzoffset_to_seconds(x)
  if (any(seconds %% 3600 != 0)) {
    stop("Offsets that are not whole hours have no Etc/GMT time zone: ",
         paste(unique(x[seconds %% 3600 != 0]), collapse = ", "),
         call. = FALSE)
  }
  hours = -seconds / 3600
  x = ifelse(hours > 0, paste0("+", hours), as.character(hours))
  x = paste0("Etc/GMT", x)
  if (!all(x %in% OlsonNames())) {
    stop("No Olson time zone for offset: ",
         paste(unique(x[!x %in% OlsonNames()]), collapse = ", "),
         call. = FALSE)
  }
  x
}

# Convert "+HH:MM" or "+HH:MM:SS" offsets to signed seconds from UTC
tzoffset_to_seconds = function(x) {
  x = trimws(x)
  pattern = "^([+-]?)([0-9]{1,2}):([0-9]{2})(:([0-9]{2}))?$"
  if (!all(grepl(pattern, x))) {
    stop("Timezone offsets must look like +HH:MM or +HH:MM:SS, got: ",
         paste(unique(x[!grepl(pattern, x)]), collapse = ", "),
         call. = FALSE)
  }
  sign = ifelse(sub(pattern, "\\1", x) == "-", -1, 1)
  hours = as.numeric(sub(pattern, "\\2", x))
  minutes = as.numeric(sub(pattern, "\\3", x))
  secs = sub(pattern, "\\5", x)
  secs = ifelse(nzchar(secs), as.numeric(secs), 0)
  sign * (hours * 3600 + minutes * 60 + secs)
}

check_file_exists = function(path) {
  if (!is.character(path) || length(path) == 0 || anyNA(path) ||
      !all(file.exists(path))) {
    stop("File does not exist: ",
         paste(path[is.na(path) | !file.exists(path)], collapse = ", "),
         call. = FALSE)
  }
  invisible(path)
}

# Compare the header start time to the first data time, warning on mismatch.
# Safe for zero-row data and missing first times.
warn_header_start_mismatch = function(header, time) {
  header_start = header$start
  if (is.null(header_start)) {
    header_start = header$start_time
  }
  if (length(header_start) != 1 || length(time) == 0) {
    return(invisible(FALSE))
  }
  time1 = time[1]
  mismatch = !is.na(header_start) && !is.na(time1) &&
    as.numeric(header_start) != as.numeric(time1)
  if (mismatch) {
    warning(paste0("Header start date is not same time as data$time,",
                   " may want to use apply_tz = FALSE."))
  }
  invisible(mismatch)
}


read_csv_safe = function(..., guess_max = Inf) {
  x = readr::read_csv(..., guess_max = guess_max)
  p = readr::problems(x)
  cn = list(...)[["col_names"]]
  # problems() rows count the header line only when the file has one
  has_header = is.null(cn) || isTRUE(cn)
  if (nrow(p) > 0) {
    message(paste(utils::capture.output(print(p)), collapse = "\n"))

    rows = unique(p$row)
    if (has_header) {
      rows = rows - 1
    }
    bad_data = x[rows, unique(p$col)]
    message("Bad Data:\n")
    message(paste(utils::capture.output(print(bad_data)), collapse = "\n"))
  }
  readr::stop_for_problems(x)
  x
}

# Lightweight replacement for janitor::clean_names() (snake case).
# Handles camelCase, spaces/punctuation, "%" and "#", leading digits,
# empty names, and duplicates (suffixed `_2`, `_3`, ...).
clean_names = function(x) {
  if (is.data.frame(x)) {
    names(x) = clean_names(names(x))
    return(x)
  }
  x = as.character(x)
  x[is.na(x)] = ""
  x = iconv(x, to = "ASCII//TRANSLIT", sub = "")
  x[is.na(x)] = ""
  x = gsub("'", "", x, fixed = TRUE)
  x = gsub("%", "_percent_", x, fixed = TRUE)
  x = gsub("#", "_number_", x, fixed = TRUE)
  # camelCase / PascalCase boundaries: aB -> a_B, ABc -> A_Bc
  x = gsub("([a-z0-9])([A-Z])", "\\1_\\2", x)
  x = gsub("([A-Z])([A-Z][a-z])", "\\1_\\2", x)
  x = tolower(x)
  x = gsub("[^a-z0-9]+", "_", x)
  x = gsub("^_+|_+$", "", x)
  x[x == ""] = "x"
  x = sub("^([0-9])", "x\\1", x)
  # First occurrence keeps its name; later duplicates get the smallest
  # `_k` (k >= 2) suffix not already in use, so a generated name can never
  # collide with an existing one (e.g. a, A, a_2 -> a, a_3, a_2).
  dup = which(duplicated(x))
  if (length(dup) > 0) {
    used = unique(x)
    for (i in dup) {
      k = 2L
      repeat {
        cand = paste0(x[i], "_", k)
        if (!cand %in% used) break
        k = k + 1L
      }
      x[i] = cand
      used = c(used, cand)
    }
  }
  x
}
