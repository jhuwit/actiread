# Transform timezone offset to timezone

Converts UTC offsets such as `"-05:00"` (5 hours behind UTC) into the
matching fixed-offset Olson time zone. Note that `Etc/GMT` zones use an
inverted sign convention, so `"-05:00"` is `"Etc/GMT+5"`.

## Usage

``` r
tzoffset_to_tz(x)
```

## Arguments

- x:

  A character vector of offsets in the form `"+HH:MM"` or `"+HH:MM:SS"`

## Value

A character vector

## Examples

``` r
tzoffset_to_tz(c("+00:00", "-05:00", "+01:00"))
#> [1] "Etc/GMT0"  "Etc/GMT+5" "Etc/GMT-1"
```
