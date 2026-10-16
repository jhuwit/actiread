# Read Parmay Tech Matrix Binary File

Reads `.bin`/`.BIN` files from Parmay Tech Matrix devices using
[`GGIRread::readParmayMatrix()`](https://rdrr.io/pkg/GGIRread/man/readParmayMatrix.html).

## Usage

``` r
acti_read_parmay_matrix(
  path,
  start = 1,
  end = NULL,
  tz = "UTC",
  ...,
  apply_tz = TRUE,
  verbose = TRUE
)

acti_read_parmay_matrix_header(path)
```

## Arguments

- path:

  Path to Matrix binary file, optionally compressed.

- start:

  index of the first packet to read, passed to
  [GGIRread::readParmayMatrix](https://rdrr.io/pkg/GGIRread/man/readParmayMatrix.html)

- end:

  index of the last packet to read, passed to
  [GGIRread::readParmayMatrix](https://rdrr.io/pkg/GGIRread/man/readParmayMatrix.html).
  `NULL` reads all packets.

- tz:

  time zone for the data `time`, passed to `desiredtz` in
  [GGIRread::readParmayMatrix](https://rdrr.io/pkg/GGIRread/man/readParmayMatrix.html).
  If `NULL` or `""`, no time conversion is done.

- ...:

  additional arguments to pass to
  [`GGIRread::readParmayMatrix()`](https://rdrr.io/pkg/GGIRread/man/readParmayMatrix.html),
  such as `read_gyro`, `read_temp`, or `read_heart`

- apply_tz:

  turn the `time` column into a `POSIXct` in time zone `tz`. If `FALSE`,
  `time` is left as seconds since 1970-01-01.

- verbose:

  print diagnostic messages

## Value

A `tibble` with columns `time`, `X`, `Y`, `Z` (in g), any other sensors
read, and attributes of a header, sample rate, quality-control log
(`qc_log`), and transformations

## Examples

``` r
data = acti_read_parmay_matrix(acti_example_parmay_matrix())
#> ✔ Read 12587 rows from Matrix file
header = acti_read_parmay_matrix_header(acti_example_parmay_matrix())
```
