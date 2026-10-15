# Read an actigraphy or sensor file

Guess the appropriate reader from the file extension and pass additional
arguments through to that reader. Compressed `.gz` files are dispatched
by their underlying extension.

## Usage

``` r
acti_read(file, ..., verbose = TRUE)
```

## Arguments

- file:

  Path to a file to read.

- ...:

  Arguments passed to the selected reader.

- verbose:

  Print the selected reader before reading. Defaults to `TRUE`.

## Value

The result from the selected reader.

## Examples

``` r
if (FALSE) { # \dontrun{
data = acti_read("activity.gt3x")
} # }
```
