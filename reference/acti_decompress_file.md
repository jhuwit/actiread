# Decompress an Activity-data File

Decompresses `.bz2`, `.gz`, and `.xz` files to a temporary file. If
`extension` is `NULL`, the destination extension is inferred after
removing the compression extension from `path`.

## Usage

``` r
acti_decompress_file(path, extension = NULL)
```

## Arguments

- path:

  Path to an activity-data file, optionally compressed.

- extension:

  Output file extension. Defaults to `NULL`, which infers the extension
  from `path` after removing its compression extension.

## Value

A list with `path`, the usable file path, and `temporary`, which is
`TRUE` when a temporary decompressed file was created. Callers should
delete `path` when `temporary` is `TRUE`.

## Examples

``` r
file = acti_decompress_file(acti_example_cwa())
if (file$temporary) {
  unlink(file$path)
}
```
