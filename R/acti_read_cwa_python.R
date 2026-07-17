#' Read CWA File with `actipy`
#'
#' @inheritParams acti_read_cwa
#'
#' @param lowpass_hz Frequency of low pass filter
#' @param calibrate_gravity perform gravity calibration method of van
#' Hees et al. 2014
#' <https://pubmed.ncbi.nlm.nih.gov/25103964/>
#' @param detect_nonwear Flag nonwear episodes in the data by setting them to
#' `NA`. Non-wear episodes are inferred from long periods of no movement.
#' 90 minute munte windows based on 10-second rolling windows with a
#' threshold of 0.015g standard deviation tolerance
#' @param resample_hz Target frequency (Hz) to resample the signal. If
#' `"uniform"`, uses the device's sample rate to fix sampling errors. Pass
#' `FALSE` to disable.
#' @param ... additional arguments to pass to `actipy.read_device`
#'
#' @returns A `tibble` with attributes of a header, sample rate, and
#' transformations
#' @export
#' @examples
#' if (requireNamespace("reticulate", quietly = TRUE) &&
#'     requireNamespace("arrow", quietly = TRUE)) {
#'     if (reticulate::py_module_available("actipy") &&
#'       reticulate::py_module_available("pyarrow")) {
#'         data = acti_py_read_cwa(acti_example_cwa())
#'     }
#' }
acti_py_read_cwa = function(path,
                            lowpass_hz = FALSE,
                            calibrate_gravity = FALSE,
                            detect_nonwear = FALSE,
                            resample_hz = FALSE,
                            ...,
                            tz = "UTC",
                            apply_tz = TRUE,
                            verbose = TRUE
) {
  time = NULL
  rm(list = c("time"))

  stopifnot(requireNamespace("reticulate", quietly = TRUE))
  stopifnot(requireNamespace("arrow", quietly = TRUE))

  ap = reticulate::import("actipy", convert = FALSE)
  data = ap$read_device(
    path,
    lowpass_hz = lowpass_hz,
    calibrate_gravity = calibrate_gravity,
    detect_nonwear = detect_nonwear,
    resample_hz = resample_hz,
    ...)
  summary = reticulate::py_get_item(data, 1L)
  summary = reticulate::py_to_r(summary)
  data = reticulate::py_get_item(data, 0L)

  # make time a column
  data = data$reset_index()
  data$time = data$time$dt$tz_localize("UTC")

  # this is why we need pyarrow
  tfile = tempfile(fileext = ".feather")
  data$to_feather(tfile)
  rm(data); gc()
  data = arrow::read_feather(tfile)
  file.remove(tfile)

  data = actibase::set_transformations(data,
                                       "acti_py_read_cwa:data_read_via_actipy_read_device",
                                       add = TRUE)

  suppressWarnings({
    hdr = acti_read_cwa_header(path)
  })
  ns = c(names(summary), tolower(names(summary)))
  ns = c(ns, "sample_rate")

  summary = c(summary, hdr[setdiff(names(hdr), ns)])
  # need to join with hdr from above
  attr(data, "header") = summary
  attr(data, "sample_rate") = summary$ResampleRate
  if (is.null(attr(data, "sample_rate"))) {
    attr(data, "sample_rate") = summary$SampleRate
  }

  # time goes first
  data = data |>
    dplyr::select(time, dplyr::everything())

  data = acti_cwa_apply_tz(data,
                           tz = tz,
                           apply_tz = apply_tz,
                           verbose = verbose)

  data
}


#' Require `actipy` for `reticulate`
#'
#' @param ... additional arguments to pass to [reticulate::py_require]
#' @param python_version version of python passed to [reticulate::py_require]
#'
#' @returns invisible NULL
#' @export
acti_require_actipy = function(..., python_version = "3.9") {
  stopifnot(requireNamespace("reticulate", quietly = TRUE))
  reticulate::py_require(
    c("actipy", "pyarrow", "pip", "statsmodels"),
    python_version = python_version,
    ...)
}
