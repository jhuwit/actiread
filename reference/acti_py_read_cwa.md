# Read CWA File with `actipy`

Read CWA File with `actipy`

## Usage

``` r
acti_py_read_cwa(
  path,
  lowpass_hz = FALSE,
  calibrate_gravity = FALSE,
  detect_nonwear = FALSE,
  resample_hz = FALSE,
  ...,
  tz = "UTC",
  apply_tz = TRUE,
  verbose = TRUE
)
```

## Arguments

- path:

  Path to cwa file

- lowpass_hz:

  Frequency of low pass filter

- calibrate_gravity:

  perform gravity calibration method of van Hees et al. 2014
  <doi:10.1152/japplphysiol.00421.2014>

- detect_nonwear:

  Flag nonwear episodes in the data by setting them to `NA`. Non-wear
  episodes are inferred from long periods of no movement. 90 minute
  munte windows based on 10-second rolling windows with a threshold of
  0.015g standard deviation tolerance

- resample_hz:

  Target frequency (Hz) to resample the signal. If `"uniform"`, uses the
  device's sample rate to fix sampling errors. Pass `FALSE` to disable.

- ...:

  additional arguments to pass to `actipy.read_device`

- tz:

  time zone for the data `time`, passed to `desiredtz` argument in
  [GGIRread::readAxivity](https://rdrr.io/pkg/GGIRread/man/readAxivity.html).
  If NULL or `""`, no time conversion is done.

- apply_tz:

  turn the `time` column into a `POSIXct` and apply the timezone

- verbose:

  print diagnostic messages, higher values = more verbosity.

## Value

A `tibble` with attributes of a header, sample rate, and transformations

## Examples

``` r
# \donttest{
if (requireNamespace("reticulate", quietly = TRUE) &&
    requireNamespace("arrow", quietly = TRUE)) {
    if (reticulate::py_module_available("actipy") &&
      reticulate::py_module_available("pyarrow")) {
        data = acti_py_read_cwa(acti_example_cwa())
    }
}
#> Downloading uv...
#> Done!
# }
```
