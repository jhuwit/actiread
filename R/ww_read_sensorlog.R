# zip_file = "data/SensorLog/OCEANS_011_BL/SensorLogFiles_OCEANS_011_BL_221208_11-55-16.zip"

is_zip_file = function(file) {
  ext = tolower(tools::file_ext(file))
  ext == "zip"
}

unzip_files = function(file) {
  if (any(is_zip_file(file))) {
    if (!all(is_zip_file(file))) {
      stop(paste0("ww_read_sensorlog works with only zip file or a vector of ",
                  "csv files"))
    }
    orig_file = file
    file = lapply(file, function(r) {
      tfile = tempfile()
      utils::unzip(r, exdir = tfile)
    })
    file = unlist(file)
  }
  file
}

#' Read SensorLog Data
#'
#' @param file A character vector of SensorLog files, usually from unzipping
#' the file
#' @param verbose print diagnostic messages.  Either logical or integer, where
#' higher values are higher levels of verbosity.
#' @param robust if `TRUE` then [rewrite_sensorlog_csv] is run on the data
#' to try to fix any shifts with the data.
#' @return A `data.frame` of data
#' @export
#' @examples
#' file = ww_example_sensorlog_file()
#' df = ww_read_sensorlog(file)
#' head(df)
#' result = ww_process_sensorlog(df, check_data = FALSE, tz = "GMT")
#' out = ww_minute_sensorlog(result)
#' out = ww_summarize_sensorlog(result)
ww_read_sensorlog = function(
    file,
    verbose = FALSE,
    robust = FALSE
) {
  file = unzip_files(file)
  lon_zero = lat_zero = lat = lon = NULL
  rm(list = c("lat", "lon", "lat_zero", "lon_zero"))

  names(file) = file

  cn = ww_sensorlog_csv_colnames_mapping()
  spec = ww_sensorlog_csv_spec()

  if (robust) {
    file = sapply(file, rewrite_sensorlog_csv, verbose = verbose > 1)
  }
  data =
    purrr::map_df(names(file), function(nx) {
      x = file[[nx]]
      r = read_csv_safe(x, progress = FALSE, col_types = spec)
      # r = readr::read_csv(x, col_types = spec)
      if (nrow(r) == 0) {
        return(NULL)
      }
      make_na_cols = c("locationSpeedAccuracy(m/s)")
      missing_cols = setdiff(cn, colnames(r))
      if (length(missing_cols) > 0) {
        missing_cols = unique(missing_cols)
        msg = paste0("Missing expected columns from ", nx, ": ",
                     paste(missing_cols, collapse = ", ")
        )
        message(msg)
        warning(msg)
        for (icol in intersect(missing_cols, make_na_cols)) {
          r[[icol]] = NA_real_
        }
      }
      r = r[, cn]
      colnames(r) = names(cn)

      # r = r %>%
      #   dplyr::mutate(
      #     lat = ifelse(abs(lat) < 0.00001, NA_real_, lat),
      #     lon = ifelse(abs(lon) < 0.00001, NA_real_, lon)
      #   )

      # should add lat_zero in there
      r = r %>%
        dplyr::mutate(
          lat_zero = abs(lat) < 0.00001,
          lon_zero = abs(lon) < 0.00001
        )
      r = r %>%
        dplyr::mutate(
          lat = ifelse(lat_zero, NA_real_, lat),
          lon = ifelse(lon_zero, NA_real_, lon)
        )
      r = r %>%
        dplyr::mutate(
          file = nx
        )

      r
    }, .progress = verbose > 0)
  if (nrow(data) > 0) {
    data = data %>%
      dplyr::select(file, dplyr::everything())
  }
  data
}






#' @export
#' @rdname ww_read_sensorlog
ww_sensorlog_csv_spec = function() {
  spec = readr::cols(
    `loggingTime(txt)` = readr::col_character(),
    `loggingSample(N)` = readr::col_double(),
    `locationTimestamp_since1970(s)` = readr::col_double(),
    `locationLatitude(WGS84)` = readr::col_double(),
    `locationLongitude(WGS84)` = readr::col_double(),
    `locationAltitude(m)` = readr::col_double(),
    `locationSpeed(m/s)` = readr::col_double(),
    `locationSpeedAccuracy(m/s)` = readr::col_double(),
    `accelerometerAccelerationX(G)` = readr::col_double(),
    `accelerometerAccelerationY(G)` = readr::col_double(),
    `accelerometerAccelerationZ(G)` = readr::col_double(),
    .default = readr::col_character()
  )
  spec
}

#' @export
#' @rdname ww_read_sensorlog
ww_sensorlog_csv_colnames_mapping = function() {
  cn =  c(
    time = "loggingTime(txt)",
    index = "loggingSample(N)",
    timestamp = "locationTimestamp_since1970(s)",
    lat = "locationLatitude(WGS84)",
    lon = "locationLongitude(WGS84)",
    altitude = "locationAltitude(m)",
    speed = "locationSpeed(m/s)",
    speed_accuracy = "locationSpeedAccuracy(m/s)",
    accel_X = "accelerometerAccelerationX(G)",
    accel_Y = "accelerometerAccelerationY(G)",
    accel_Z = "accelerometerAccelerationZ(G)")
  cn
}
