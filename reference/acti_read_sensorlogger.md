# Read SensorLogger Data

Read SensorLogger Data

## Usage

``` r
acti_sensorlogger_location_colnames_mapping()

acti_sensorlogger_location_spec()

acti_read_sensorlogger_location(file, ...)

acti_read_sensorlogger(file, verbose = FALSE, ...)

acti_read_sensorlogger_general(file, ..., verbose = FALSE)
```

## Arguments

- file:

  A character vector of SensorLogger files, usually from unzipping the
  file, or a zip file of SensorLogger files

- ...:

  additional arguments to pass to \[readr::read_csv()\]. If \`verbose =
  FALSE\`, then \`progress = FALSE\` and \`show_col_types = FALSE\`,
  unless otherwise overridden

- verbose:

  print diagnostic messages. Either logical or integer, where higher
  values are higher levels of verbosity.

## Value

A \`data.frame\` of data
