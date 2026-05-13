#' Activity/Actigraphy Example Data
#'
#' @returns A file path
#' @export
#' @rdname acti_example_data
#'
#' @examples
#' acti_example_gt3x()
#' acti_example_cwa()
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
