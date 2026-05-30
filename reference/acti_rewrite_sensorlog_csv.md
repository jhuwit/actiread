# Rewrite a CSV that may have issues with export from SensorLog

Rewrite a CSV that may have issues with export from SensorLog

## Usage

``` r
acti_rewrite_sensorlog_csv(
  file,
  outfile = tempfile(fileext = ".csv"),
  verbose = FALSE
)
```

## Arguments

- file:

  Input CSV file

- outfile:

  Output CSV file

- verbose:

  Print Diagnostic messages

## Value

A file path to the new CSV

## Examples

``` r
sl_file = actiread::acti_example_sensorlog_file()
tfile = tempfile()
files = utils::unzip(sl_file, exdir = tfile)
result = actiread::acti_rewrite_sensorlog_csv(files)
```
