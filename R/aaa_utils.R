
tzoffset_to_tz = function(x) {
  stopifnot(all(grepl(":00", x)))
  x = sub(":00:00$", "", x)
  x = sub(":00$", "", x)
  stopifnot(nchar(x) <= 3)
  x = as.numeric(x)
  x = ifelse(x > 0, paste0("+", x), as.character(x))
  x = paste0("Etc/GMT", x)
  stopifnot(x %in% OlsonNames())
  x
}
