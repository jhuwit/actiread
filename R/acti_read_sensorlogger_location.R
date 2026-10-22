
#' @export
#' @rdname acti_read_sensorlogger
acti_sensorlogger_location_colnames_mapping = function() {
  # cn =  c(
  #   time = "time",
  #   seconds_elapsed = "seconds_elapsed",
  #   altitude = "altitude",
  #   speedAccuracy = "speed_accuracy",
  #   bearingAccuracy = "bearing_accuracy",
  #   latitude = "lat",
  #   altitudeAboveMeanSeaLevel = "altitude_above_mean_sea_level",
  #   bearing = "bearing",
  #   horizontalAccuracy = "horizontal_accuracy",
  #   verticalAccuracy = "vertical_accuracy",
  #   longitude = "lon",
  #   speed = "speed"
  # )
  cn = c(
    time = "time",
    seconds_elapsed = "seconds_elapsed",
    altitude = "altitude",
    speed_accuracy = "speedAccuracy",
    bearing_accuracy = "bearingAccuracy",
    lat = "latitude",
    altitude_above_mean_sea_level = "altitudeAboveMeanSeaLevel",
    bearing = "bearing",
    horizontal_accuracy = "horizontalAccuracy",
    vertical_accuracy = "verticalAccuracy",
    lon = "longitude",
    speed = "speed"
  )
  cn
}

#' @export
#' @rdname acti_read_sensorlogger
acti_sensorlogger_location_spec = function() {
  spec = readr::cols(
    time = readr::col_double(),
    seconds_elapsed = readr::col_double(),
    altitude = readr::col_double(),
    speedAccuracy = readr::col_double(),
    bearingAccuracy = readr::col_double(),
    latitude = readr::col_double(),
    altitudeAboveMeanSeaLevel = readr::col_double(),
    bearing = readr::col_double(),
    horizontalAccuracy = readr::col_double(),
    verticalAccuracy = readr::col_double(),
    longitude = readr::col_double(),
    speed = readr::col_double()
  )
  spec
}


create_lat_lon_zero = function(df) {
  lon_zero = lat_zero = lat = lon = NULL
  rm(list = c("lat", "lon", "lat_zero", "lon_zero"))

  # should add lat_zero in there
  df = df %>%
    dplyr::mutate(
      lat_zero = abs(lat) < 0.00001,
      lon_zero = abs(lon) < 0.00001
    )
  df = df %>%
    dplyr::mutate(
      lat = ifelse(lat_zero, NA_real_, lat),
      lon = ifelse(lon_zero, NA_real_, lon)
    )
  df
}

#' @export
#' @rdname acti_read_sensorlogger
acti_read_sensorlogger_location = function(path, ...) {
  check_file_exists(path)
  cn = acti_sensorlogger_location_colnames_mapping()
  args = list(path, ...)
  if (is.null(args[["col_types"]])) {
    # only use the parsers for the columns in the file to avoid warnings
    file_cn = colnames(readr::read_csv(
      path, n_max = 0, col_types = readr::cols(.default = "c"),
      progress = FALSE, show_col_types = FALSE))
    spec = acti_sensorlogger_location_spec()
    spec$cols = spec$cols[intersect(names(spec$cols), file_cn)]
    args$col_types = spec
  }
  df = do.call(read_csv_safe, args)
  if (nrow(df) == 0) {
    return(NULL)
  }
  missing_cols = setdiff(cn, colnames(df))
  if (length(missing_cols) > 0) {
    warning("Missing expected columns from ", path, ": ",
            paste(missing_cols, collapse = ", "), ", filling with NA")
    for (icol in missing_cols) {
      df[[icol]] = NA_real_
    }
  }
  df = df[, cn]
  colnames(df) = names(cn)
  df$time = acti_convert_sensorlogger_time(df$time)
  df = create_lat_lon_zero(df)
  df$file = path
  stub = acti_sensorlogger_stub(path)
  df$cat_type_sensor = stub
  df
}

