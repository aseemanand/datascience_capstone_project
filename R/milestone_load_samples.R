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

wc_line_count_zip_member <- function(zip_path, member_path) {
  if (.Platform$OS.type != "unix") {
    return(NA_integer_)
  }
  z <- normalizePath(zip_path, winslash = "/", mustWork = TRUE)
  sh_cmd <- paste(
    "unzip -p",
    shQuote(z, type = "sh"),
    shQuote(member_path, type = "sh"),
    "| wc -l"
  )
  out <- suppressWarnings(
    system2("/bin/sh", c("-c", sh_cmd), stdout = TRUE, stderr = FALSE)
  )
  if (length(out) < 1L) {
    return(NA_integer_)
  }
  as.integer(trimws(strsplit(out[[1]], "\\s+")[[1]][1]))
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

zip_entry_length_bytes <- function(zip_path, member_path) {
  lst <- tryCatch(
    utils::unzip(zip_path, list = TRUE),
    error = function(e) NULL
  )
  if (is.null(lst) || !("Name" %in% names(lst)) || !("Length" %in% names(lst))) {
    return(NA_real_)
  }
  nm <- lst$Name
  hit <- nm == member_path | gsub("\\\\", "/", nm) == member_path
  if (!any(hit, na.rm = TRUE)) {
    return(NA_real_)
  }
  as.numeric(lst$Length[which(hit)[1]])
}

corpus_file_inventory_from_spec <- function(spec) {
  if (spec$mode == "dir") {
    return(corpus_file_inventory(spec$paths))
  }
  zip_path <- spec$zip_path
  members <- spec$members
  dplyr::bind_rows(lapply(names(members), function(nm) {
    inner <- members[[nm]]
    dplyr::tibble(
      source = nm,
      path = paste0(basename(zip_path), "::", inner),
      size_mb = zip_entry_length_bytes(zip_path, inner) / (1024^2),
      lines_total = wc_line_count_zip_member(zip_path, inner)
    )
  }))
}

read_corpus_lines_head <- function(path, label, n_max) {
  con <- file(path, open = "rt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  txt <- readLines(con, n = n_max, warn = FALSE)
  dplyr::tibble(source = label, line = seq_along(txt), text = txt)
}

read_corpus_lines_head_zip <- function(zip_path, member_path, label, n_max) {
  txt <- readLines(
    unz(zip_path, member_path),
    n = n_max,
    warn = FALSE,
    encoding = "UTF-8"
  )
  dplyr::tibble(source = label, line = seq_along(txt), text = txt)
}

assemble_head_samples <- function(spec, lines_per_source) {
  if (spec$mode == "dir") {
    paths <- spec$paths
    out <- dplyr::bind_rows(
      read_corpus_lines_head(paths$blogs, "blogs", lines_per_source),
      read_corpus_lines_head(paths$news, "news", lines_per_source),
      read_corpus_lines_head(paths$twitter, "twitter", lines_per_source)
    )
  } else {
    m <- spec$members
    zp <- spec$zip_path
    out <- dplyr::bind_rows(
      read_corpus_lines_head_zip(zp, m$blogs, "blogs", lines_per_source),
      read_corpus_lines_head_zip(zp, m$news, "news", lines_per_source),
      read_corpus_lines_head_zip(zp, m$twitter, "twitter", lines_per_source)
    )
  }
  dplyr::mutate(
    out,
    chars = nchar(.data$text),
    words = count_non_ws_tokens(.data$text),
    source = factor(.data$source, levels = c("blogs", "news", "twitter"))
  )
}
