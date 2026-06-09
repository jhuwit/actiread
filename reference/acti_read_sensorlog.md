# Read SensorLog Data

Read SensorLog Data

## Usage

``` r
acti_read_sensorlog(file, verbose = FALSE, robust = FALSE)

acti_sensorlog_csv_spec()

acti_sensorlog_csv_colnames_mapping()
```

## Arguments

- file:

  A character vector of SensorLog files, usually from unzipping the file

- verbose:

  print diagnostic messages. Either logical or integer, where higher
  values are higher levels of verbosity.

- robust:

  if `TRUE` then
  [acti_rewrite_sensorlog_csv](https://jhuwit.github.io/actiread/reference/acti_rewrite_sensorlog_csv.md)
  is run on the data to try to fix any shifts with the data.

## Value

A `data.frame` of data

## Examples

``` r
library(actiread)
file = acti_example_sensorlog_file()
df = acti_read_sensorlog(file)
head(df)
#> # A tibble: 6 × 14
#>   file   time  index timestamp   lat   lon altitude speed speed_accuracy accel_X
#>   <chr>  <chr> <dbl>     <dbl> <dbl> <dbl>    <dbl> <dbl>          <dbl>   <dbl>
#> 1 /tmp/… 2025…     1    1.74e9  39.3 -76.6     46.3    -1             -1  0.411 
#> 2 /tmp/… 2025…     2    1.74e9  39.3 -76.6     46.3    -1             -1  0.0908
#> 3 /tmp/… 2025…     3    1.74e9  39.3 -76.6     46.3    -1             -1  0.125 
#> 4 /tmp/… 2025…     4    1.74e9  39.3 -76.6     46.3    -1             -1  0.0636
#> 5 /tmp/… 2025…     5    1.74e9  39.3 -76.6     46.3    -1             -1  0.0993
#> 6 /tmp/… 2025…     6    1.74e9  39.3 -76.6     46.3    -1             -1  0.0702
#> # ℹ 4 more variables: accel_Y <dbl>, accel_Z <dbl>, lat_zero <lgl>,
#> #   lon_zero <lgl>
```
