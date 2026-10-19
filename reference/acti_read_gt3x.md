# Read GT3X file

Read GT3X file

## Usage

``` r
acti_read_gt3x(
  path,
  asDataFrame = TRUE,
  imputeZeroes = TRUE,
  verbose = TRUE,
  ...,
  digits = 3L,
  fill_zeroes = TRUE,
  apply_tz = FALSE,
  check_attributes = TRUE,
  tz = "GMT"
)

acti_info_gt3x(path, ...)
```

## Arguments

- path:

  Path to gt3x file

- asDataFrame:

  convert to an `activity_df`, see `as.data.frame.activity`

- imputeZeroes:

  Impute zeros in case there are missingness? Default is `TRUE`. If
  `FALSE`, the time series will be incomplete in case there is
  missingness.

- verbose:

  print diagnostic messages, higher values = more verbosity.

- ...:

  additional arguments to pass to
  [`read.gt3x::read.gt3x()`](https://rdrr.io/pkg/read.gt3x/man/read.gt3x.html)

- digits:

  number of digits to round the acceleration values to, passed to
  [`read.gt3x::read.gt3x()`](https://rdrr.io/pkg/read.gt3x/man/read.gt3x.html)
  (requires `read.gt3x >= 1.3.0`). The default `3L` matches both
  [`read.gt3x::read.gt3x()`](https://rdrr.io/pkg/read.gt3x/man/read.gt3x.html)
  and ActiLife, so the data agree with ActiLife exports. Set to `NULL`
  to use the
  [`read.gt3x::read.gt3x()`](https://rdrr.io/pkg/read.gt3x/man/read.gt3x.html)
  default. If you will resample the data (e.g. to 30 Hz for activity
  counts), read with `digits` of at least `6L` (e.g. `8L`), resample,
  and then round to 3 digits: rounding to 3 before resampling loses
  precision, and rounding values already rounded to 5 digits rounds
  twice (e.g. `0.1234996` to `0.12350` to `0.124`).

- fill_zeroes:

  Rows with all zeros will be filled in with the last observation
  carried forward as is done with ActiLife. Recommended

- apply_tz:

  Apply the timezone from the header `TimeZone` attribute, if available

- check_attributes:

  Check that the attributes are included This is a sanity check,
  including checking that `sample_rate` is in the attributes.

- tz:

  timezone to display the data in when `apply_tz = TRUE`. The data read
  in via
  [`read.gt3x::read.gt3x()`](https://rdrr.io/pkg/read.gt3x/man/read.gt3x.html)
  says the timezone is GMT, but the time values are the device's local
  clock time. When `apply_tz = TRUE`, the header `TimeZone` offset is
  used to recover the true time, which is then shown in `tz` (the
  default `"GMT"` gives UTC times). Set to `NULL` to keep the
  fixed-offset zone from the header (e.g. `"Etc/GMT+4"` for `-04:00`),
  or UTC if the offset is not a whole number of hours.

## Value

A `data.frame`

## Examples

``` r
library(actiread)
data = acti_read_gt3x(acti_example_gt3x())
#> ℹ Filling zeros in data
#> ✔ Filled zeros in data
#> ℹ Timezone not applied to data
data = acti_read_gt3x(
  acti_example_gt3x(),
  tz = NULL,
  apply_tz = FALSE,
  verbose = FALSE,
  fill_zeroes = FALSE
)
info = acti_info_gt3x(acti_example_gt3x())
```
