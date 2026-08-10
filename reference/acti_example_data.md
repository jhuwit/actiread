# Activity/Actigraphy Example Data

Activity/Actigraphy Example Data

## Usage

``` r
acti_example_gt3x()

acti_example_cwa()

acti_example_geneactiv()

acti_example_sensorlog_file()

acti_example_sensorlogger_file()

acti_example_sensorlogger_location_file()
```

## Value

A file path

## Examples

``` r
library(actiread)
acti_example_gt3x()
#> [1] "/home/runner/work/_temp/Library/actiread/extdata/TAS1H30182785_2019-09-17.gt3x.gz"
acti_example_cwa()
#> [1] "/home/runner/work/_temp/Library/actiread/extdata/ax3_testfile.cwa.gz"
acti_example_sensorlogger_file()
#> [1] "/home/runner/work/_temp/Library/actiread/extdata/SensorLogger-2025-04-28_22-04-35.zip"
```
