#' Read SensorLogger Data
#'
#' @param file A character vector of SensorLogger files, usually from unzipping
#' the file, or a zip file of SensorLogger files
#' @param verbose print diagnostic messages.  Either logical or integer, where
#' higher values are higher levels of verbosity.
#' @param ... additional arguments to pass to [readr::read_csv()].
#' If `verbose = FALSE`, then `progress = FALSE` and `show_col_types = FALSE`,
#' unless otherwise overridden
#' @return A `data.frame` of data
#' @export
ww_read_sensorlogger = function(
    file,
    verbose = FALSE,
    ...
) {
  lon_zero = lat_zero = lat = lon = NULL
  rm(list = c("lat", "lon", "lat_zero", "lon_zero"))

  file = unzip_files(file)
  stub = ww_sensorlogger_stub(file)
  names(file) = stub

  data_list = purrr::map(file, function(r) {
    data = ww_sensorlogger_reader(r, verbose = verbose, ...,  type = NULL)
  })
  if (length(file) == 1 && length(data_list) == 1) {
    data_list = data_list[[1]]
  }

  data_list
}


ww_convert_sensorlogger_time = function(x) {
  as_datetime_safe(x/1000/1000/1000)
}



ww_sensorlogger_stub = function(x) {
  stub = sub("[.]csv($|[.]gz$)", "", basename(x), ignore.case = TRUE)
  stub = tolower(stub)
  stub = sub("^sensorlogger_", "", stub)
  stub = sub("uncalibrated", "_uncalibrated", stub)
  stub
}




#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_general = function(file, ..., verbose = FALSE) {
  df = read_csv_safe(file, ...)
  if (nrow(df) == 0) {
    return(NULL)
  }
  df = df %>%
    janitor::clean_names()
  if (assertthat::has_name(df, "time")) {
    df$time = ww_convert_sensorlogger_time(df$time)
  }

  df$file = file
  stub = ww_sensorlogger_stub(file)
  df$cat_type_sensor = stub

  if (nrow(df) > 0) {
    df = df %>%
      dplyr::select(file, dplyr::everything())
  }
  df
}

#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_accelerometer = ww_read_sensorlogger_general
#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_accelerometer_uncalibrated = ww_read_sensorlogger_general
#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_annotation = ww_read_sensorlogger_general

#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_battery = ww_read_sensorlogger_general

#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_gravity = ww_read_sensorlogger_general
#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_gyroscope_uncalibrated = ww_read_sensorlogger_general
#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_metadata = ww_read_sensorlogger_general

#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_orientation = ww_read_sensorlogger_general

#' @export
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_pedometer = ww_read_sensorlogger_general

ww_sensorlogger_reader = function(file, ..., type = NULL, verbose = FALSE) {
  if (is.null(type)) {
    type = ww_sensorlogger_stub(file)
  }
  func = switch(
    type,
    accelerometer = ww_read_sensorlogger_general,
    accelerometer_uncalibrated = ww_read_sensorlogger_general,
    annotation = ww_read_sensorlogger_general,
    battery = ww_read_sensorlogger_general,
    gravity = ww_read_sensorlogger_general,
    gyroscope = ww_read_sensorlogger_general,
    gyroscope_uncalibrated = ww_read_sensorlogger_general,
    location = ww_read_sensorlogger_location,
    metadata = ww_read_sensorlogger_general,
    orientation = ww_read_sensorlogger_general,
    pedometer = ww_read_sensorlogger_general,
    ww_read_sensorlogger_general
    )
  args = list(...)
  if (!verbose & !"progress" %in% names(args)) {
    args$progress = FALSE
  }
  if (!verbose & !"show_col_types" %in% names(args)) {
    args$show_col_types = FALSE
  }
  args$file = file
  do.call(func, args = args)
}




