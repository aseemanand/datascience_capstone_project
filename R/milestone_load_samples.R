# Read head samples and file inventory for SwiftKey English lines.

wc_line_count_unix <- function(path) {
  if (.Platform$OS.type != "unix") {
    return(NA_integer_)
  }
  wc <- suppressWarnings(system2("wc", c("-l", path), stdout = TRUE))
  if (length(wc) != 1L) {
    return(NA_integer_)
  }
  as.integer(trimws(strsplit(wc, "\\s+")[[1]][1]))
}

corpus_file_inventory <- function(paths) {
  p <- unlist(paths)
  dplyr::tibble(
    source = names(paths),
    path = p,
    size_mb = file.info(p)$size / (1024^2),
    lines_total = vapply(p, wc_line_count_unix, integer(1))
  )
}

read_corpus_lines_head <- function(path, label, n_max) {
  con <- file(path, open = "rt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  txt <- readLines(con, n = n_max, warn = FALSE)
  dplyr::tibble(source = label, line = seq_along(txt), text = txt)
}

assemble_head_samples <- function(paths, lines_per_source) {
  out <- dplyr::bind_rows(
    read_corpus_lines_head(paths$blogs, "blogs", lines_per_source),
    read_corpus_lines_head(paths$news, "news", lines_per_source),
    read_corpus_lines_head(paths$twitter, "twitter", lines_per_source)
  )
  dplyr::mutate(
    out,
    chars = nchar(.data$text),
    words = count_non_ws_tokens(.data$text),
    source = factor(.data$source, levels = c("blogs", "news", "twitter"))
  )
}
