testthat::context("SensorLog and SensorLogger readers")

write_named_csv <- function(dir, filename, lines) {
  path = file.path(dir, filename)
  writeLines(lines, path)
  path
}

extract_zip_files <- function(zip_file) {
  exdir = tempfile("sensorlogger-")
  dir.create(exdir)
  utils::unzip(zip_file, exdir = exdir)
  list.files(exdir, recursive = TRUE, full.names = TRUE)
}

extdata_file <- function(filename) {
  path = system.file("extdata", filename, package = "actiread")
  if (nzchar(path)) {
    return(path)
  }
  normalizePath(file.path("..", "..", "inst", "extdata", filename), mustWork = TRUE)
}

testthat::test_that("SensorLog helpers and schemas are available", {
  zip_file = actiread::acti_example_sensorlog_file()
  if (!nzchar(zip_file)) {
    zip_file = extdata_file("SensorLogFiles_my_iOS_device_250311_14-55-58.zip")
  }
  sensorlogger_zip = actiread::acti_example_sensorlogger_file()
  if (!nzchar(sensorlogger_zip)) {
    sensorlogger_zip = extdata_file("SensorLogger-2025-04-28_22-04-35.zip")
  }
  sensorlogger_location = actiread::acti_example_sensorlogger_location_file()
  if (!nzchar(sensorlogger_location)) {
    sensorlogger_location = extdata_file("SensorLogger_Location.csv.gz")
  }

  csv_file = tempfile(fileext = ".csv")
  writeLines("a,b\n1,2", csv_file)

  testthat::expect_true(file.exists(zip_file))
  testthat::expect_true(file.exists(sensorlogger_zip))
  testthat::expect_true(file.exists(sensorlogger_location))
  testthat::expect_true(actiread:::is_zip_file(zip_file))
  testthat::expect_false(actiread:::is_zip_file(csv_file))
  testthat::expect_identical(actiread:::unzip_files(csv_file), csv_file)

  testthat::expect_error(
    actiread:::unzip_files(c(zip_file, csv_file)),
    "only zip file or a vector of csv files"
  )

  sensorlog_cn = actiread:::acti_sensorlog_csv_colnames_mapping()
  sensorlog_spec = actiread:::acti_sensorlog_csv_spec()
  sensorlogger_cn = actiread:::acti_sensorlogger_location_colnames_mapping()
  sensorlogger_spec = actiread:::acti_sensorlogger_location_spec()

  testthat::expect_identical(
    names(sensorlog_cn),
    c(
      "time", "index", "timestamp", "lat", "lon", "altitude",
      "speed", "speed_accuracy", "accel_X", "accel_Y", "accel_Z"
    )
  )
  testthat::expect_true("loggingTime(txt)" %in% names(sensorlog_spec$cols))
  testthat::expect_identical(
    names(sensorlogger_cn),
    c(
      "time", "seconds_elapsed", "altitude", "speed_accuracy",
      "bearing_accuracy", "lat", "altitude_above_mean_sea_level", "bearing",
      "horizontal_accuracy", "vertical_accuracy", "lon", "speed"
    )
  )
  testthat::expect_true("latitude" %in% names(sensorlogger_spec$cols))

  testthat::expect_equal(
    format(actiread::acti_convert_sensorlogger_time(1e9), tz = "UTC"),
    "1970-01-01 00:00:01"
  )
})

testthat::test_that("SensorLog rewrite fixes pedometer and battery shifts", {
  pedometer_dir = tempfile("sensorlog-pedometer-")
  dir.create(pedometer_dir)
  pedometer_file = write_named_csv(
    pedometer_dir,
    "pedometer.csv",
    c(
      "id,pedometerFloorDescended(N),pedometerEndDate(txt),extra",
      "1,null,2025-03-11"
    )
  )
  pedometer_out = actiread:::acti_rewrite_sensorlog_csv(
    pedometer_file,
    verbose = TRUE
  )
  testthat::expect_equal(
    readLines(pedometer_out),
    c(
      "id,pedometerFloorDescended(N),pedometerEndDate(txt),extra",
      "1,null,,2025-03-11"
    )
  )

  battery_dir = tempfile("sensorlog-battery-")
  dir.create(battery_dir)
  battery_file = write_named_csv(
    battery_dir,
    "battery.csv",
    c(
      "id,pedometerFloorDescended(N),pedometerEndDate(txt),batteryTimeStamp_since1970(s),batteryState(R),batteryLevel(Z)",
      "1,0,2025-03-11,,1"
    )
  )
  battery_out = actiread:::acti_rewrite_sensorlog_csv(battery_file)
  testthat::expect_equal(
    readLines(battery_out),
    c(
      "id,pedometerFloorDescended(N),pedometerEndDate(txt),batteryTimeStamp_since1970(s),batteryState(R),batteryLevel(Z)",
      "1,0,2025-03-11,,1,"
    )
  )
})

testthat::test_that("SensorLog reader handles the shipped archive, missing columns, and empty files", {
  example_zip = extdata_file("SensorLogFiles_my_iOS_device_250311_14-55-58.zip")
  example_data = actiread::acti_read_sensorlog(example_zip)

  testthat::expect_s3_class(example_data, "tbl_df")
  testthat::expect_true(nrow(example_data) > 0)
  testthat::expect_true(all(c("file", "time", "lat", "lon", "lat_zero", "lon_zero") %in% names(example_data)))
  testthat::expect_false(anyNA(example_data$lat_zero))
  testthat::expect_false(anyNA(example_data$lon_zero))
  testthat::expect_equal(length(unique(example_data$file)), 1L)
  testthat::expect_match(unique(example_data$file), "my_iOS_device.csv$")

  example_files = actiread:::unzip_files(example_zip)
  testthat::expect_true(length(example_files) == 1L)

  missing_dir = tempfile("sensorlog-missing-")
  dir.create(missing_dir)
  missing_file = write_named_csv(
    missing_dir,
    "SensorLog.csv",
    c(
      paste(
        c(
          "loggingTime(txt)",
          "loggingSample(N)",
          "locationTimestamp_since1970(s)",
          "locationLatitude(WGS84)",
          "locationLongitude(WGS84)",
          "locationAltitude(m)",
          "locationSpeed(m/s)",
          "accelerometerAccelerationX(G)",
          "accelerometerAccelerationY(G)",
          "accelerometerAccelerationZ(G)",
          "pedometerFloorDescended(N)",
          "pedometerEndDate(txt)"
        ),
        collapse = ","
      ),
      "2025-03-11 14:44:11,1,1741707851,0,0,1.2,-1,0.41,0.12,0.34,null,2025-03-11"
    )
  )

  testthat::expect_warning(
    missing_data <- actiread::acti_read_sensorlog(missing_file, robust = TRUE),
    "Missing expected columns"
  )
  testthat::expect_equal(nrow(missing_data), 1L)
  testthat::expect_true(is.na(missing_data$speed_accuracy[1]))
  testthat::expect_true(is.na(missing_data$lat[1]))
  testthat::expect_true(is.na(missing_data$lon[1]))
  testthat::expect_true(missing_data$lat_zero[1])
  testthat::expect_true(missing_data$lon_zero[1])
  testthat::expect_equal(missing_data$file[1], missing_file)

  empty_file = write_named_csv(
    missing_dir,
    "empty.csv",
    c(
      "loggingTime(txt),loggingSample(N),locationTimestamp_since1970(s),locationLatitude(WGS84),locationLongitude(WGS84),locationAltitude(m),locationSpeed(m/s),locationSpeedAccuracy(m/s),accelerometerAccelerationX(G),accelerometerAccelerationY(G),accelerometerAccelerationZ(G)"
    )
  )
  empty_data = actiread::acti_read_sensorlog(empty_file)
  testthat::expect_equal(nrow(empty_data), 0L)
  testthat::expect_equal(ncol(empty_data), 0L)
})

testthat::test_that("SensorLogger helpers normalize stubs and convert time", {
  testthat::expect_equal(
    actiread:::acti_sensorlogger_stub("SensorLogger_Accelerometer.csv"),
    "accelerometer"
  )
  testthat::expect_equal(
    actiread:::acti_sensorlogger_stub("SensorLogger_AccelerometerUncalibrated.csv"),
    "accelerometer_uncalibrated"
  )
  testthat::expect_equal(
    actiread:::acti_sensorlogger_stub("SensorLogger_Location.csv.gz"),
    "location"
  )
  testthat::expect_equal(
    format(actiread::acti_convert_sensorlogger_time(1e9), tz = "UTC"),
    "1970-01-01 00:00:01"
  )
})

testthat::test_that("SensorLogger readers work for the shipped files and dispatch correctly", {
  location_file = extdata_file("SensorLogger_Location.csv.gz")
  location_data = actiread::acti_read_sensorlogger_location(
    location_file,
    show_col_types = FALSE
  )

  testthat::expect_s3_class(location_data, "tbl_df")
  testthat::expect_true(inherits(location_data$time, "POSIXct"))
  testthat::expect_true(all(c("file", "cat_type_sensor", "lat_zero", "lon_zero") %in% names(location_data)))
  testthat::expect_true(all(location_data$file == location_file))
  testthat::expect_equal(unique(location_data$cat_type_sensor), "location")

  general_dir = tempfile("sensorlogger-general-")
  dir.create(general_dir)
  general_file = write_named_csv(
    general_dir,
    "Accelerometer.csv",
    c(
      "time,x,y",
      "1000000000,1,2"
    )
  )
  general_data = actiread::acti_read_sensorlogger_general(
    general_file,
    show_col_types = FALSE
  )
  testthat::expect_s3_class(general_data, "tbl_df")
  testthat::expect_true(inherits(general_data$time, "POSIXct"))
  testthat::expect_equal(unique(general_data$cat_type_sensor), "accelerometer")
  testthat::expect_equal(general_data$file[1], general_file)

  no_time_file = write_named_csv(
    general_dir,
    "Other.csv",
    c(
      "foo,bar",
      "1,2"
    )
  )
  no_time_data = actiread:::acti_sensorlogger_reader(
    no_time_file,
    type = "unknown"
  )
  testthat::expect_s3_class(no_time_data, "tbl_df")
  testthat::expect_false("time" %in% names(no_time_data))
  testthat::expect_equal(unique(no_time_data$cat_type_sensor), "other")

  single_file_data = actiread::acti_read_sensorlogger(
    general_file,
    show_col_types = FALSE
  )
  testthat::expect_s3_class(single_file_data, "tbl_df")
  testthat::expect_equal(single_file_data$file[1], general_file)
  testthat::expect_true(inherits(single_file_data$time, "POSIXct"))

  archive_data = actiread::acti_read_sensorlogger(
    extdata_file("SensorLogger-2025-04-28_22-04-35.zip"),
    show_col_types = FALSE
  )
  testthat::expect_type(archive_data, "list")
  testthat::expect_equal(length(archive_data), 16L)
  testthat::expect_true(all(c("location", "accelerometer", "battery", "gravity") %in% names(archive_data)))
  testthat::expect_true(inherits(archive_data$location$time, "POSIXct"))
})

testthat::test_that("SensorLogger location reader returns NULL for empty files", {
  empty_dir = tempfile("sensorlogger-empty-")
  dir.create(empty_dir)
  empty_file = write_named_csv(
    empty_dir,
    "Location.csv",
    c(
      "time,seconds_elapsed,altitude,speedAccuracy,bearingAccuracy,latitude,altitudeAboveMeanSeaLevel,bearing,horizontalAccuracy,verticalAccuracy,longitude,speed"
    )
  )

  testthat::expect_null(
    actiread::acti_read_sensorlogger_location(empty_file, show_col_types = FALSE)
  )
})
