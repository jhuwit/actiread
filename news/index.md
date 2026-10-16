# Changelog

## actiread 0.7.0

- Added
  [`acti_read_genea()`](https://jhuwit.github.io/actiread/reference/acti_read_genea.md)/[`acti_read_genea_header()`](https://jhuwit.github.io/actiread/reference/acti_read_genea.md)
  for original ‘Genea’ `.bin` files and
  [`acti_read_parmay_matrix()`](https://jhuwit.github.io/actiread/reference/acti_read_parmay_matrix.md)/[`acti_read_parmay_matrix_header()`](https://jhuwit.github.io/actiread/reference/acti_read_parmay_matrix.md)
  for ‘Parmay Tech Matrix’ `.bin` files, with example data
  ([`acti_example_genea()`](https://jhuwit.github.io/actiread/reference/acti_example_data.md),
  [`acti_example_parmay_matrix()`](https://jhuwit.github.io/actiread/reference/acti_example_data.md))
  from ‘GGIRread’.
- [`acti_read()`](https://jhuwit.github.io/actiread/reference/acti_read.md)
  now inspects the first kilobyte of `.bin` files (and files with
  unknown extensions) to choose between GENEActiv, Genea, Matrix, and
  CWA, and dispatches `.bz2` and `.xz` compressed files.
- [`tzoffset_to_tz()`](https://jhuwit.github.io/actiread/reference/tzoffset_to_tz.md)
  now returns the correctly-signed `Etc/GMT` zone (`"-05:00"` is
  `"Etc/GMT+5"`) and gives informative errors.
- `acti_read_gt3x(apply_tz = TRUE)` now handles non-whole-hour offsets,
  shows the corrected times in `tz` (previously a non-UTC `tz` gave
  shifted times), and `tz = NULL` keeps the header’s fixed-offset zone
  instead of the system time zone.
- CWA and GT3X readers no longer error on zero-row data or a missing
  first time;
  [`acti_py_read_cwa()`](https://jhuwit.github.io/actiread/reference/acti_py_read_cwa.md)
  accepts `tz = NULL`.
- [`acti_read_cwa_header()`](https://jhuwit.github.io/actiread/reference/acti_read_cwa.md)
  uses the fast header parser, and
  [`acti_read_geneactiv_header()`](https://jhuwit.github.io/actiread/reference/acti_read_geneactiv.md)
  no longer reads the whole file.
- [`acti_read_geneactiv()`](https://jhuwit.github.io/actiread/reference/acti_read_geneactiv.md)
  gains `apply_tz`.
- Header `acceleration_min`/`acceleration_max` are now numeric for all
  readers.
- [`acti_read_sensorlogger()`](https://jhuwit.github.io/actiread/reference/acti_read_sensorlogger.md)
  always returns a list for zip files, and
  [`acti_read_sensorlogger_location()`](https://jhuwit.github.io/actiread/reference/acti_read_sensorlogger.md)
  uses its column specification and fills missing columns with `NA`.
- [`acti_rewrite_sensorlog_csv()`](https://jhuwit.github.io/actiread/reference/acti_rewrite_sensorlog_csv.md)
  handles quoted fields containing commas and columns after the battery
  fields.
- Readers now give a clear error for files that do not exist.

## actiread 0.6.0

- Added
  [`acti_read()`](https://jhuwit.github.io/actiread/reference/acti_read.md)
  to guess the reader from CWA, GT3X, and GENEActiv file extensions,
  including `.gz` compressed files.

## actiread 0.5.0

CRAN release: 2026-08-21

- Added
  [`acti_decompress_file()`](https://jhuwit.github.io/actiread/reference/acti_decompress_file.md)
  to decompress supported activity-data files.
- Added a fast internal CWA-header parser for the Python reader,
  preserving the native CWA header and appending the `actipy` processing
  summary.
- Reused centralized decompression across CWA, GENEActiv, and Python
  readers.
- Marked the optional Python CWA example as `\\dontrun{}` to avoid
  Python startup time during package checks.

## actiread 0.4.0

- Adding in ‘GENEActiv’ readers.

## actiread 0.3.0

CRAN release: 2026-07-15

- Fixing bug in setting header if no `accrange` in
  `acti_gt3x_process_time` and `acti_cwa_process_time`.
- Added in `acti_process_header` to normalize this.

## actiread 0.2.0

CRAN release: 2026-07-07

- CRAN Re-submission.

## actiread 0.1.0

- `read.gt3x` digits argument passed.
- CRAN Submission.

## actiread 0.0.2

- Added `actiread` functions to read activity data from a file.
