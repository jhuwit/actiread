## R CMD check results

0 errors | 0 warnings | 2 notes

* This is an update to the CRAN version (0.9.0).  The readers now return
  logical `missing_time` and `unsorted_time` attributes and warn on missing or
  unsorted times, 'janitor' and 'purrr' are no longer imported, and
  `tzoffset_to_tz()` is re-exported from 'actibase' (>= 0.9.0) instead of
  being defined here (behavior unchanged).  This release requires 'actibase'
  0.9.0, which is submitted/published before this package.

* checking CRAN incoming feasibility ... NOTE
  Size of tarball: 7339979 bytes

* checking installed package size ... NOTE
  installed size is  7.2Mb
  sub-directories of 1Mb or more:
    extdata   7.0Mb

  The size comes from two example 'SensorLogger' and 'SensorLog' zip files
  in `inst/extdata`, which were also in the 0.5.0 release.  They are real
  device exports in the zipped multi-file formats these readers parse, and
  are used in the examples and tests.
