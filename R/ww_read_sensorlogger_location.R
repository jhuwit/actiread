
#' @export
#' @rdname ww_read_sensorlogger
ww_sensorlogger_location_colnames_mapping = function() {
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
#' @rdname ww_read_sensorlogger
ww_sensorlogger_location_spec = function() {
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
#' @rdname ww_read_sensorlogger
ww_read_sensorlogger_location = function(file, ...) {
  df = read_csv_safe(file, ...)
  if (nrow(df) == 0) {
    return(NULL)
  }
  cn = ww_sensorlogger_location_colnames_mapping()
  spec = ww_sensorlogger_location_spec()

  icn = intersect(cn, colnames(df))
  df = df[, cn]
  colnames(df) = names(cn)
  df$time = ww_convert_sensorlogger_time(df$time)
  df = create_lat_lon_zero(df)
  df$file = file
  stub = ww_sensorlogger_stub(file)
  df$cat_type_sensor = stub
  df
}

