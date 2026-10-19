## R CMD check results

0 errors | 0 warnings | 2 notes

* This is an update to the CRAN version (0.5.0).  It adds readers for
  'Genea' and 'Parmay Tech Matrix' binary files, fixes time zone handling,
  and adds a `digits` argument to `acti_read_gt3x()` so the default output
  matches ActiLife.

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
