
<!-- badges: start -->

[![R-CMD-check](https://github.com/jhuwit/actiread/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jhuwit/actiread/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://app.codecov.io/gh/jhuwit/actiread/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jhuwit/actiread?branch=main)
<!-- badges: end -->

<!-- README.md is generated from README.Rmd. Please edit that file -->

# actiread Package

`actiread` reads raw actigraphy files and returns tidy data frames that
are ready for downstream analysis.

It currently focuses on:

- reading `gt3x` files
- reading `cwa` files
- Reading [SensorLog](https://sensorlog.berndthomas.net/) files
- Reading [SensorLogger](https://www.tszheichoi.com/sensorlogger) files
- loading small example files bundled with the package
- inspecting GT3X header metadata
- handling timezone conversion during import

## Installation

You can install `actiread` from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("jhuwit/actiread")
```

## Quick start

``` r
library(actibase)
library(actiread)

gt3x_file = acti_example_gt3x()
cwa_file = acti_example_cwa()

gt3x = acti_read_gt3x(gt3x_file, verbose = FALSE)
cwa = acti_read_cwa(cwa_file, verbose = FALSE)

head(gt3x)
#> # A tibble: 6 × 4
#>   time                    X      Y     Z
#>   <dttm>              <dbl>  <dbl> <dbl>
#> 1 2019-09-17 22:40:00 0      0.008 0.996
#> 2 2019-09-17 22:40:00 0.016  0     1.01 
#> 3 2019-09-17 22:40:00 0.02  -0.008 1.00 
#> 4 2019-09-17 22:40:00 0.016 -0.012 1.01 
#> 5 2019-09-17 22:40:00 0.016 -0.008 1.01 
#> 6 2019-09-17 22:40:00 0.008 -0.008 1.01
head(cwa)
#> # A tibble: 6 × 7
#>   time                    x      y      z  temp battery light
#>   <dttm>              <dbl>  <dbl>  <dbl> <dbl>   <dbl> <dbl>
#> 1 2019-02-26 10:55:06 0.328  0.984  0.203  25.6       0   283
#> 2 2019-02-26 10:55:06 0.822 -0.343 -0.368  25.6       0   283
#> 3 2019-02-26 10:55:06 0.874 -0.390 -0.390  25.6       0   283
#> 4 2019-02-26 10:55:06 0.890 -0.391 -0.391  25.6       0   283
#> 5 2019-02-26 10:55:06 0.891 -0.376 -0.391  25.6       0   283
#> 6 2019-02-26 10:55:06 0.876 -0.360 -0.376  25.6       0   283

res = acti_standardize_data(gt3x)
resampled = acti_resample(res, sample_rate = 30L)
get_transformations(resampled)
#> [1] "acti_resample:sample_rate_attribute_changed_to_30"
#> [2] "acti_resample:linear_resampled_to_30Hz"           
#> [3] "acti_read_gt3x:timezone_GMT_forced"               
#> [4] "acti_read_gt3x:timezone_Etc/GMT-4_applied"        
#> [5] "acti_read_gt3x:attributes_set"                    
#> [6] "acti_fill_zeros:filled_zeros"                     
#> [7] "acti_read_gt3x:data_read"
```

``` r
tzoffset_to_tz(c("+00:00", "-05:00", "+01:00"))
#> [1] "Etc/GMT0"  "Etc/GMT-5" "Etc/GMT+1"
```

## What you can do

`actiread` is a focused import layer for actigraphy data:

- read `.gt3x`/`.gt3x.gz` files with `acti_read_gt3x()`
- read `.cwa`/`.cwa.gz` files with `acti_read_cwa()`
- inspect GT3X metadata with `acti_info_gt3x()`
- use bundled sample files with `acti_example_gt3x()` and
  `acti_example_cwa()`
- control timezone handling during import with `tz` and `apply_tz`

The readers return tidy objects with attached metadata such as the file
header and sampling rate, which makes it straightforward to hand the
result off to your own cleaning, summarization, or modeling code.
