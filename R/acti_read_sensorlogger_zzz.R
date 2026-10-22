#' Read SensorLogger Data
#'
#' @param path A character vector of SensorLogger files, usually from unzipping
#' the file, or a zip file of SensorLogger files
#' @param verbose print diagnostic messages.  Either logical or integer, where
#' higher values are higher levels of verbosity.
#' @param ... additional arguments to pass to [readr::read_csv()].
#' If `verbose = FALSE`, then `progress = FALSE` and `show_col_types = FALSE`,
#' unless otherwise overridden
#' @return A `data.frame` of data if a single CSV file is given, otherwise a
#' named list of `data.frame`s, one per sensor file (always a list for zip
#' files)
#' @export
acti_read_sensorlogger = function(
    path,
    verbose = TRUE,
    ...
) {
  lon_zero = lat_zero = lat = lon = NULL
  rm(list = c("lat", "lon", "lat_zero", "lon_zero"))

  input_is_zip = any(is_zip_file(path))
  path = unzip_files(path)
  stub = acti_sensorlogger_stub(path)
  names(path) = make.unique(stub, sep = "_")

  data_list = purrr::map(path, function(r) {
    data = acti_sensorlogger_reader(r, verbose = verbose, ...,  type = NULL)
  })
  if (!input_is_zip && length(path) == 1 && length(data_list) == 1) {
    data_list = data_list[[1]]
  }

  data_list
}


#' @inherit actibase::as_datetime_safe
#' @export
acti_convert_sensorlogger_time = function(x) {
  as_datetime_safe(x/1000/1000/1000)
}



acti_sensorlogger_stub = function(x) {
  stub = sub("[.]csv($|[.]gz$)", "", basename(x), ignore.case = TRUE)
  stub = tolower(stub)
  stub = sub("^sensorlogger_", "", stub)
  stub = sub("uncalibrated", "_uncalibrated", stub)
  stub
}




#' @export
#' @rdname acti_read_sensorlogger
acti_read_sensorlogger_general = function(path, ..., verbose = TRUE) {
  check_file_exists(path)
  df = read_csv_safe(path, ...)
  if (nrow(df) == 0) {
    return(NULL)
  }
  df = df %>%
    janitor::clean_names()
  if (assertthat::has_name(df, "time")) {
    df$time = acti_convert_sensorlogger_time(df$time)
  }

  df$file = path
  stub = acti_sensorlogger_stub(path)
  df$cat_type_sensor = stub

  if (nrow(df) > 0) {
    df = df %>%
      dplyr::select(file, dplyr::everything())
  }
  df
}

acti_sensorlogger_reader = function(path, ..., type = NULL, verbose = TRUE) {
  if (is.null(type)) {
    type = acti_sensorlogger_stub(path)
  }
  func = switch(
    type,
    accelerometer = acti_read_sensorlogger_general,
    accelerometer_uncalibrated = acti_read_sensorlogger_general,
    annotation = acti_read_sensorlogger_general,
    battery = acti_read_sensorlogger_general,
    gravity = acti_read_sensorlogger_general,
    gyroscope = acti_read_sensorlogger_general,
    gyroscope_uncalibrated = acti_read_sensorlogger_general,
    location = acti_read_sensorlogger_location,
    metadata = acti_read_sensorlogger_general,
    orientation = acti_read_sensorlogger_general,
    pedometer = acti_read_sensorlogger_general,
    acti_read_sensorlogger_general
    )
  args = list(...)
  if (!verbose & !"progress" %in% names(args)) {
    args$progress = FALSE
  }
  if (!verbose & !"show_col_types" %in% names(args)) {
    args$show_col_types = FALSE
  }
  args$path = path
  do.call(func, args = args)
}

