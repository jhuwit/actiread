#' Rewrite a CSV that may have issues with export from SensorLog
#'
#' @param path Input CSV file
#' @param outfile Output CSV file
#' @param verbose Print Diagnostic messages
#'
#' @return A file path to the new CSV
#' @export
#' @examples
#' sl_file = actiread::acti_example_sensorlog_file()
#' tfile = tempfile()
#' files = utils::unzip(sl_file, exdir = tfile)
#' result = actiread::acti_rewrite_sensorlog_csv(files)
acti_rewrite_sensorlog_csv = function(
    path,
    outfile = tempfile(fileext = ".csv"),
    verbose = TRUE
) {
  if (verbose) {
    message(
      paste0("File being processed:\n",
             path)
    )
  }
  check_file_exists(path)
  # read the files in
  txt = readLines(path)
  cn = strsplit(txt[1], ",")[[1]]
  ind = which(cn ==  "pedometerFloorDescended(N)")
  ind2 = which(cn ==  "pedometerEndDate(txt)")
  # different line enders
  if (length(ind) > 0) {
    stopifnot(ind2 == (ind+1))
  }

  # fix for oceans
  bat_ind = which(cn ==   "batteryTimeStamp_since1970(s)")
  bat_ind_r = which(cn ==  "batteryState(R)")
  bat_ind_z = which(cn ==  "batteryLevel(Z)")
  if (length(bat_ind) > 0) {
    stopifnot(bat_ind_z == (bat_ind+2))
    stopifnot(bat_ind_r == (bat_ind+1))
    stopifnot(bat_ind_z == length(cn) ||
                bat_ind_z == (length(cn) - 1) )
  }

  # split the data in , - only lines with quotes need the slower split that
  # ignores commas inside quoted fields
  ss = strsplit(txt, ",", fixed = TRUE)
  has_quote = grepl('"', txt, fixed = TRUE)
  if (any(has_quote)) {
    ss[has_quote] = strsplit(txt[has_quote],
                             ',(?=(?:[^"]*"[^"]*")*[^"]*$)', perl = TRUE)
  }

  l = sapply(ss, length)
  max_length = max(l)
  # stopifnot(max(max_length - l) <= 1)
  ss = lapply(ss, function(x) {
    # elements with "null" cause a shift in the pedometer columns
    if (length(ind) > 0 &&
        isTRUE(tolower(x)[ind] == "null") &&
        length(x) %in% c(max_length - 1, max_length - 2)) {
      x = append(x, "", after = ind)
    }
    # an empty battery timestamp drops the battery level field
    if (length(bat_ind) > 0 &&
        isTRUE(tolower(x)[bat_ind] == "") &&
        length(x) == max_length - 1) {
      x = append(x, "", after = bat_ind_r)
    }
    x
  })
  # make sure consistent with the data
  l = sapply(ss, length)
  stopifnot(all(l == max_length))
  ss = sapply(ss, paste, collapse = ",")
  # write it out
  writeLines(ss, outfile)
  outfile
}
