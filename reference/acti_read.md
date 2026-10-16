# Read an actigraphy or sensor file

Guess the appropriate reader from the file extension and pass additional
arguments through to that reader. Compressed `.gz`, `.bz2`, and `.xz`
files are dispatched by their underlying extension. Because 'GENEActiv',
'Genea', and 'Parmay Matrix' devices all write `.bin` files, the first
kilobyte of `.bin` files (and files with an unknown extension) is
inspected to pick the reader.

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
data = acti_read(acti_example_cwa(), verbose = FALSE)
data = acti_read(acti_example_genea(), verbose = FALSE)
```
