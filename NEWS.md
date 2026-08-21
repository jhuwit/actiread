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
