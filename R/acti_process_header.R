acti_process_header = function(data) {
  header = data$header
  if (is.null(header)) {
    header = attr(data, "header")
  }
  if (is.null(header)) {
    header = list()
  }
  if (is.list(data) && !is.null(data$data)) {
    data = data$data
    if (length(header) == 0) {
      header = attr(data, "header")
    }
  }

  if (!is.null(header$accrange)) {
    header$acceleration_min = paste0("-", header$accrange)
    header$acceleration_max = as.character(header$accrange)
  }
  header$sample_rate = header$frequency
  if (is.null(header$sample_rate)) {
    header$sample_rate = attr(data, "sample_rate")
  }
  header
}
