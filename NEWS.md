# actiread 0.9.0

* `acti_read()`, `acti_read_sensorlog()`, `acti_read_sensorlogger()`,
  `acti_read_sensorlogger_location()`, `acti_read_sensorlogger_general()`, and
  `acti_rewrite_sensorlog_csv()` take `path` instead of `file`, matching the
  other readers.
* The SensorLog/SensorLogger readers and `acti_rewrite_sensorlog_csv()` now
  default to `verbose = TRUE`.

# actiread 0.8.0

* `acti_read_gt3x()` gains a `digits` argument with default `3L`, matching
  `read.gt3x::read.gt3x()` and ActiLife (previously it silently read at 5
  digits).  `digits = NULL` uses the `read.gt3x` default.  If you resample
  the data, read at 6 or more digits (e.g. `8L`) and round to 3 afterwards.
* With `read.gt3x` < 1.3.0, which cannot take `digits` and always rounds to
  3 digits, `acti_read_gt3x()` only warns when `digits` is not 3.

# actiread 0.7.0

* Added `acti_read_genea()`/`acti_read_genea_header()` for original 'Genea'
  `.bin` files and `acti_read_parmay_matrix()`/`acti_read_parmay_matrix_header()`
  for 'Parmay Tech Matrix' `.bin` files, with example data
  (`acti_example_genea()`, `acti_example_parmay_matrix()`) from 'GGIRread'.
* `acti_read()` now inspects the first kilobyte of `.bin` files (and files with
  unknown extensions) to choose between GENEActiv, Genea, Matrix, and CWA, and
  dispatches `.bz2` and `.xz` compressed files.
* `tzoffset_to_tz()` now returns the correctly-signed `Etc/GMT` zone
  (`"-05:00"` is `"Etc/GMT+5"`) and gives informative errors.
* `acti_read_gt3x(apply_tz = TRUE)` now handles non-whole-hour offsets, shows
  the corrected times in `tz` (previously a non-UTC `tz` gave shifted times),
  and `tz = NULL` keeps the header's fixed-offset zone instead of the system
  time zone.
* CWA and GT3X readers no longer error on zero-row data or a missing first
  time; `acti_py_read_cwa()` accepts `tz = NULL`.
* `acti_read_cwa_header()` uses the fast header parser, and
  `acti_read_geneactiv_header()` no longer reads the whole file.
* `acti_read_geneactiv()` gains `apply_tz`.
* Header `acceleration_min`/`acceleration_max` are now numeric for all readers.
* `acti_read_sensorlogger()` always returns a list for zip files, and
  `acti_read_sensorlogger_location()` uses its column specification and fills
  missing columns with `NA`.
* `acti_rewrite_sensorlog_csv()` handles quoted fields containing commas and
  columns after the battery fields.
* Readers now give a clear error for files that do not exist.

# actiread 0.6.0

* Added `acti_read()` to guess the reader from CWA, GT3X, and GENEActiv file
  extensions, including `.gz` compressed files.

# actiread 0.5.0

* Added `acti_decompress_file()` to decompress supported activity-data files.
* Added a fast internal CWA-header parser for the Python reader, preserving the
  native CWA header and appending the `actipy` processing summary.
* Reused centralized decompression across CWA, GENEActiv, and Python readers.
* Marked the optional Python CWA example as `\\dontrun{}` to avoid Python
  startup time during package checks.

# actiread 0.4.0

* Adding in 'GENEActiv' readers.

# actiread 0.3.0

* Fixing bug in setting header if no `accrange` in `acti_gt3x_process_time` and `acti_cwa_process_time`.
* Added in `acti_process_header` to normalize this.

# actiread 0.2.0

* CRAN Re-submission.

# actiread 0.1.0

* `read.gt3x` digits argument passed.
* CRAN Submission.

# actiread 0.0.2

* Added `actiread` functions to read activity data from a file.
