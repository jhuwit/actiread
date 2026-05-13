# Read CWA File

Read CWA File

## Usage

``` r
acti_read_cwa(
  path,
  start = 0,
  end = Inf,
  tz = "UTC",
  ...,
  apply_tz = TRUE,
  verbose = TRUE
)
```

## Arguments

- path:

  Path to cwa file

- start:

  where to start in the file, passed to \[GGIRread::readAxivity\]

- end:

  where to end in the file, passed to \[GGIRread::readAxivity\]

- tz:

  time zone for the data \`time\`, passed to \`desiredtz\` argument in
  \[GGIRread::readAxivity\]. If NULL or \`""\`, no time conversion is
  done.

- ...:

  additional arguments to pass to \[GGIRread::readAxivity()\]

- apply_tz:

  turn the \`time\` column into a \`POSIXct\` and apply the timezone

- verbose:

  print diagnostic messages, higher values = more verbosity.

## Value

A \`tibble\` with attributes of a header, sample rate, and
transformations

## Examples

``` r
data = acti_read_cwa(acti_example_cwa())
#> ℹ Timezone applied to data
data = acti_read_cwa(
  acti_example_cwa(),
  tz = NULL,
  apply_tz = FALSE,
  verbose = FALSE
)
```
