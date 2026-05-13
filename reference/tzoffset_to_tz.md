# Transform timezone offset to timezone

Transform timezone offset to timezone

## Usage

``` r
tzoffset_to_tz(x)
```

## Arguments

- x:

  A character vector

## Value

A character vector

## Examples

``` r
tzoffset_to_tz(c("+00:00", "-05:00", "+01:00"))
#> [1] "Etc/GMT0"  "Etc/GMT-5" "Etc/GMT+1"
```
