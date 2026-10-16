# Read GENEActiv Binary File

Read GENEActiv Binary File

## Usage

``` r
acti_read_geneactiv(
  path,
  start = 0,
  end = Inf,
  tz = "UTC",
  ...,
  apply_tz = TRUE,
  verbose = TRUE
)

acti_read_geneactiv_header(path)
```

## Arguments

- path:

  Path to geneactiv binary file

- start:

  where to start in the file, passed to
  [GGIRread::readGENEActiv](https://rdrr.io/pkg/GGIRread/man/readGENEActiv.html)

- end:

  where to end in the file, passed to
  [GGIRread::readGENEActiv](https://rdrr.io/pkg/GGIRread/man/readGENEActiv.html)

- tz:

  time zone for the data `time`, passed to `desiredtz` argument in
  [GGIRread::readGENEActiv](https://rdrr.io/pkg/GGIRread/man/readGENEActiv.html).
  If NULL or `""`, no time conversion is done.

- ...:

  additional arguments to pass to
  [`GGIRread::readGENEActiv()`](https://rdrr.io/pkg/GGIRread/man/readGENEActiv.html)

- apply_tz:

  turn the `time` column into a `POSIXct` in time zone `tz`. If `FALSE`,
  `time` is left as seconds since 1970-01-01.

- verbose:

  print diagnostic messages, higher values = more verbosity.

## Value

A `tibble` with attributes of a header, sample rate, and transformations

## Examples

``` r
data = acti_read_geneactiv(acti_example_geneactiv())
data = acti_read_geneactiv(
  acti_example_geneactiv(),
  tz = NULL,
  apply_tz = FALSE,
  verbose = FALSE
)
header = acti_read_geneactiv_header(acti_example_geneactiv())
```
