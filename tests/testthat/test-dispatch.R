recompress <- function(path, compression, extension) {
  plain = actiread::acti_decompress_file(path, extension = extension)
  if (!plain$temporary) {
    tmp = tempfile(fileext = extension)
    file.copy(plain$path, tmp)
    plain = list(path = tmp, temporary = TRUE)
  }
  out = tempfile(fileext = paste0(extension, ".", compression))
  con_fun = switch(compression, bz2 = bzfile, xz = xzfile, gz = gzfile)
  con = con_fun(out, "wb")
  writeBin(readBin(plain$path, raw(), file.info(plain$path)$size), con)
  close(con)
  unlink(plain$path)
  out
}

testthat::test_that("acti_guess_reader handles compressed extensions", {
  testthat::expect_equal(actiread:::acti_guess_reader("activity.cwa.xz"),
                         "acti_read_cwa")
  testthat::expect_equal(actiread:::acti_guess_reader("activity.CWA.BZ2"),
                         "acti_read_cwa")
  testthat::expect_equal(actiread:::acti_guess_reader("activity.gt3x.xz"),
                         "acti_read_gt3x")
  testthat::expect_true(is.na(actiread:::acti_guess_reader("sensor.csv.xz")))
})

testthat::test_that("acti_guess_reader inspects .bin files to find the device", {
  testthat::expect_equal(
    actiread:::acti_guess_reader(actiread::acti_example_geneactiv()),
    "acti_read_geneactiv")
  testthat::expect_equal(
    actiread:::acti_guess_reader(actiread::acti_example_genea()),
    "acti_read_genea")
  testthat::expect_equal(
    actiread:::acti_guess_reader(actiread::acti_example_parmay_matrix()),
    "acti_read_parmay_matrix")

  # an unknown extension is still sniffed, here a CWA file
  cwa = actiread::acti_decompress_file(actiread::acti_example_cwa())
  on.exit(unlink(cwa$path), add = TRUE)
  unknown = tempfile(fileext = ".dat")
  file.copy(cwa$path, unknown)
  on.exit(unlink(unknown), add = TRUE)
  testthat::expect_equal(actiread:::acti_guess_reader(unknown),
                         "acti_read_cwa")

  # sniffing reads through compression
  xz_genea = recompress(actiread::acti_example_genea(), "xz", ".bin")
  on.exit(unlink(xz_genea), add = TRUE)
  testthat::expect_equal(actiread:::acti_guess_reader(xz_genea),
                         "acti_read_genea")

  # an unrecognised .bin file
  junk = tempfile(fileext = ".bin")
  writeBin(as.raw(seq(0, 255)), junk)
  on.exit(unlink(junk), add = TRUE)
  testthat::expect_true(is.na(actiread:::acti_guess_reader(junk)))
  testthat::expect_error(actiread::acti_read(junk, verbose = FALSE),
                         "Cannot recognise the device")

  empty = tempfile(fileext = ".bin")
  file.create(empty)
  on.exit(unlink(empty), add = TRUE)
  testthat::expect_true(is.na(actiread:::acti_sniff_reader(empty)))
})

testthat::test_that("acti_read reads CWA, GENEActiv, Genea, and Matrix files", {
  testthat::expect_message(
    cwa <- suppressWarnings(
      actiread::acti_read(actiread::acti_example_cwa(), verbose = TRUE,
                          progressBar = FALSE)
    ),
    "Using acti_read_cwa"
  )
  testthat::expect_true(all(c("time", "x", "y", "z") %in% names(cwa)))

  geneactiv = actiread::acti_read(actiread::acti_example_geneactiv(),
                                  verbose = FALSE)
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(geneactiv)))

  genea = actiread::acti_read(actiread::acti_example_genea(), verbose = FALSE)
  testthat::expect_equal(attr(genea, "sample_rate"), 80)

  mtx = actiread::acti_read(actiread::acti_example_parmay_matrix(),
                            verbose = FALSE)
  testthat::expect_equal(attr(mtx, "sample_rate"), 12.5)
})

testthat::test_that("acti_read reads .xz and .bz2 compressed files", {
  xz_cwa = recompress(actiread::acti_example_cwa(), "xz", ".cwa")
  on.exit(unlink(xz_cwa), add = TRUE)
  res = actiread::acti_read(xz_cwa, verbose = FALSE)
  testthat::expect_gt(nrow(res), 0)

  bz2_gt3x = recompress(actiread::acti_example_gt3x(), "bz2", ".gt3x")
  on.exit(unlink(bz2_gt3x), add = TRUE)
  res = actiread::acti_read(bz2_gt3x, verbose = FALSE, fill_zeroes = FALSE)
  testthat::expect_true(all(c("time", "X", "Y", "Z") %in% names(res)))
  info = actiread::acti_info_gt3x(bz2_gt3x)
  testthat::expect_true(length(info) > 0)
})

testthat::test_that("readers error clearly for files that do not exist", {
  missing = file.path(tempdir(), "does_not_exist.cwa")
  testthat::expect_error(actiread::acti_read(missing, verbose = FALSE),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_cwa(missing), "does not exist")
  testthat::expect_error(actiread::acti_read_cwa_header(missing),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_gt3x("nope.gt3x"),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_geneactiv("nope.bin"),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_genea("nope.bin"),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_parmay_matrix("nope.bin"),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_sensorlog("nope.csv"),
                         "does not exist")
  testthat::expect_error(actiread::acti_read_sensorlogger("nope.zip"),
                         "does not exist")
  testthat::expect_error(actiread::acti_rewrite_sensorlog_csv("nope.csv"),
                         "does not exist")
  testthat::expect_error(actiread::acti_read(NA_character_), "single")
})

testthat::test_that("acti_decompress_file handles uncompressed, bz2, and xz", {
  plain = actiread::acti_decompress_file(actiread::acti_example_geneactiv())
  testthat::expect_false(plain$temporary)
  testthat::expect_equal(plain$path, actiread::acti_example_geneactiv())

  original = readBin(actiread::acti_example_geneactiv(), raw(),
                     file.info(actiread::acti_example_geneactiv())$size)
  for (compression in c("bz2", "xz")) {
    compressed = recompress(actiread::acti_example_geneactiv(), compression,
                            ".bin")
    res = actiread::acti_decompress_file(compressed)
    testthat::expect_true(res$temporary)
    testthat::expect_match(res$path, "\\.bin$")
    testthat::expect_identical(
      readBin(res$path, raw(), file.info(res$path)$size), original)
    unlink(c(compressed, res$path))
  }
})
