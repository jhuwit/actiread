# Read Genea Binary File

Reads binary files from the original 'Genea' accelerometer (Unilever
Discover, UK) using
[`GGIRread::readGenea()`](https://rdrr.io/pkg/GGIRread/man/readGenea.html).
These are not 'GENEActiv' files, see
[`acti_read_geneactiv()`](https://jhuwit.github.io/actiread/reference/acti_read_geneactiv.md)
for those.

## Usage

``` r
acti_read_genea(
  path,
  start = 0,
  end = Inf,
  tz = "UTC",
  ...,
  apply_tz = TRUE,
  verbose = TRUE
)

acti_read_genea_header(path)
```

## Arguments

- path:

  Path to Genea binary file, optionally compressed.

- start:

  where to start in the file (page number or timestamp), passed to
  [GGIRread::readGenea](https://rdrr.io/pkg/GGIRread/man/readGenea.html)

- end:

  where to end in the file (page number or timestamp), passed to
  [GGIRread::readGenea](https://rdrr.io/pkg/GGIRread/man/readGenea.html).
  `Inf` reads to the end of the file.

- tz:

  time zone of the device clock. The clock time recorded by the device
  is interpreted as being in `tz`. If `NULL` or `""`, `UTC` is used.

- ...:

  not used

- apply_tz:

  turn the `time` column into a `POSIXct` in time zone `tz`. If `FALSE`,
  `time` is left as seconds since 1970-01-01 (device clock time).

- verbose:

  print diagnostic messages

## Value

A `tibble` with columns `time`, `X`, `Y`, `Z` (in g) and attributes of a
header, sample rate, and transformations

## Examples

``` r
data = acti_read_genea(acti_example_genea())
#> ✔ Read 42529 rows from Genea file
header = acti_read_genea_header(acti_example_genea())
```
