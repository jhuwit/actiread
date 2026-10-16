#' Activity/Actigraphy Example Data
#'
#' @returns A file path
#' @export
#' @rdname acti_example_data
#'
#' @examples
#' library(actiread)
#' acti_example_gt3x()
#' acti_example_cwa()
#' acti_example_sensorlogger_file()
#' acti_example_genea()
#' acti_example_parmay_matrix()
acti_example_gt3x = function() {
  system.file("extdata",
              "TAS1H30182785_2019-09-17.gt3x.gz",
              package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_cwa = function() {
  system.file("extdata",
              "ax3_testfile.cwa.gz",
              package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_geneactiv = function() {
  system.file("extdata",
              "GENEActiv_testfile.bin",
              package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_genea = function() {
  # From the GGIRread package test files (Apache License 2.0)
  system.file("extdata",
              "genea_testfile.bin.gz",
              package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_parmay_matrix = function() {
  # From the GGIRread package test files (Apache License 2.0)
  system.file("extdata",
              "mtx_12.5Hz_acc.BIN.gz",
              package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_sensorlog_file = function() {
  system.file(
    "extdata", "SensorLogFiles_my_iOS_device_250311_14-55-58.zip",
    package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_sensorlogger_file = function() {
  system.file(
    "extdata", "SensorLogger-2025-04-28_22-04-35.zip",
    package = "actiread")
}

#' @rdname acti_example_data
#' @export
acti_example_sensorlogger_location_file = function() {
  system.file(
    "extdata", "SensorLogger_Location.csv.gz",
    package = "actiread")
}

