# Actibase Baseline Workflow

``` r

library(actibase)
library(actiread)
```

## Overview

`actibase` is the foundation layer for actigraphy and activity data. It
focuses on raw file reading, standardization, calibration, resampling,
activity counts, non-wear detection, and transformation bookkeeping.

Higher-level summarization, step-count mapping, and downstream
statistical analysis are meant to live in overlay packages that build on
top of this core package.

## Reading data

The package ships with a small GT3X file and a small CWA file under
`inst/extdata`. We will use those examples here.

``` r
gt3x_file = acti_example_gt3x()
cwa_file = acti_example_cwa()

gt3x = acti_read_gt3x(gt3x_file, verbose = FALSE)
cwa = acti_read_cwa(cwa_file, verbose = FALSE)

class(gt3x)
[1] "tbl_df"     "tbl"        "data.frame"
names(gt3x)
[1] "time" "X"    "Y"    "Z"   
class(cwa)
[1] "tbl_df"     "tbl"        "data.frame"
names(cwa)
[1] "time"    "x"       "y"       "z"       "temp"    "battery" "light"  
```

The GT3X reader uses
[`read.gt3x::read.gt3x()`](https://rdrr.io/pkg/read.gt3x/man/read.gt3x.html)
underneath, while the CWA reader uses
[`GGIRread::readAxivity()`](https://rdrr.io/pkg/GGIRread/man/readAxivity.html).

If you need to inspect the GT3X metadata separately,
[`acti_info_gt3x()`](http://johnmuschelli.com/SummarizedActigraphy/reference/acti_read_gt3x.md)
parses the header information without returning the full data stream.

``` r
info = acti_info_gt3x(gt3x_file)
names(info)
 [1] "Serial Number"      "Device Type"        "Firmware"          
 [4] "Battery Voltage"    "Sample Rate"        "Start Date"        
 [7] "Stop Date"          "Last Sample Time"   "TimeZone"          
[10] "Download Date"      "Board Revision"     "Unexpected Resets" 
[13] "Acceleration Scale" "Acceleration Min"   "Acceleration Max"  
[16] "Subject Name"       "Serial Prefix"     
```

The readers also let you control timezone handling explicitly. Setting
`apply_tz = FALSE` keeps the timestamps as stored in the file, and
`tz = NULL` disables the final timezone forcing step.

``` r
gt3x_no_tz = acti_read_gt3x(
  gt3x_file,
  tz = NULL,
  apply_tz = FALSE,
  verbose = FALSE,
  fill_zeroes = FALSE
)

cwa_no_tz = acti_read_cwa(
  cwa_file,
  tz = NULL,
  apply_tz = FALSE,
  verbose = FALSE
)

get_transformations(gt3x_no_tz)
[1] "acti_read_gt3x:attributes_set" "acti_read_gt3x:data_read"     
get_transformations(cwa_no_tz)
[1] "acti_read_cwa:data_read_via_readAxivity"
```

Internally, Axivity files use fixed UTC offsets. The helper that maps
those offsets to Olson timezone names is small but useful when you need
to reason about the conversion logic:

``` r
tzoffset_to_tz(c("+00:00", "-05:00", "+01:00"))
[1] "Etc/GMT0"  "Etc/GMT-5" "Etc/GMT+1"
```

## Standardizing

The baseline package keeps the data in a consistent shape:

``` r
std = acti_standardize_data(gt3x)

head(std)
 [38;5;246m# A tibble: 6 × 4 [39m
  time                    X      Y     Z
   [3m [38;5;246m<dttm> [39m [23m               [3m [38;5;246m<dbl> [39m [23m   [3m [38;5;246m<dbl> [39m [23m  [3m [38;5;246m<dbl> [39m [23m
 [38;5;250m1 [39m 2019-09-17  [38;5;246m22:40:00 [39m 0      0.008 0.996
 [38;5;250m2 [39m 2019-09-17  [38;5;246m22:40:00 [39m 0.016  0     1.01 
 [38;5;250m3 [39m 2019-09-17  [38;5;246m22:40:00 [39m 0.02  - [31m0 [39m [31m. [39m [31m00 [39m [31m8 [39m 1.00 
 [38;5;250m4 [39m 2019-09-17  [38;5;246m22:40:00 [39m 0.016 - [31m0 [39m [31m. [39m [31m0 [39m [31m12 [39m 1.01 
 [38;5;250m5 [39m 2019-09-17  [38;5;246m22:40:00 [39m 0.016 - [31m0 [39m [31m. [39m [31m00 [39m [31m8 [39m 1.01 
 [38;5;250m6 [39m 2019-09-17  [38;5;246m22:40:00 [39m 0.008 - [31m0 [39m [31m. [39m [31m00 [39m [31m8 [39m 1.01 
```

## Resampling

You can resample a three-axis signal to a new sampling rate or to
specific timestamps:

``` r
resampled = acti_resample(std, sample_rate = 30L)
get_transformations(resampled)
[1] "acti_resample:sample_rate_attribute_changed_to_30"
[2] "acti_resample:linear_resampled_to_30Hz"           
[3] "acti_read_gt3x:timezone_GMT_forced"               
[4] "acti_read_gt3x:timezone_Etc/GMT-4_applied"        
[5] "acti_read_gt3x:attributes_set"                    
[6] "acti_fill_zeros:filled_zeros"                     
[7] "acti_read_gt3x:data_read"                         

same_times = acti_resample_to_time(
  std,
  times = lubridate::floor_date(std$time, unit = "1 second")
)
get_transformations(same_times)
[1] "acti_resample_to_time:resampled_to_specific_times"
[2] "acti_read_gt3x:timezone_GMT_forced"               
[3] "acti_read_gt3x:timezone_Etc/GMT-4_applied"        
[4] "acti_read_gt3x:attributes_set"                    
[5] "acti_fill_zeros:filled_zeros"                     
[6] "acti_read_gt3x:data_read"                         
```
