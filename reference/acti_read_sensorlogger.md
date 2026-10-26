# Read SensorLogger Data

Read SensorLogger Data

## Usage

``` r
acti_sensorlogger_location_colnames_mapping()

acti_sensorlogger_location_spec()

acti_read_sensorlogger_location(path, ...)

acti_read_sensorlogger(path, verbose = TRUE, ...)

acti_read_sensorlogger_general(path, ..., verbose = TRUE)
```

## Arguments

- path:

  A character vector of SensorLogger files, usually from unzipping the
  file, or a zip file of SensorLogger files

- ...:

  additional arguments to pass to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
  If `verbose = FALSE`, then `progress = FALSE` and
  `show_col_types = FALSE`, unless otherwise overridden

- verbose:

  print diagnostic messages. Either logical or integer, where higher
  values are higher levels of verbosity.

## Value

A `data.frame` of data if a single CSV file is given, otherwise a named
list of `data.frame`s, one per sensor file (always a list for zip files)
