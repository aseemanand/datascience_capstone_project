# Paths and validation for English SwiftKey corpora (Coursera Capstone).
# Portable defaults: corpus lives under final/en_US relative to the working directory.

default_swiftkey_en_dir <- function(root = ".") {
  normalizePath(file.path(root, "final", "en_US"), mustWork = FALSE)
}

swiftkey_en_file_paths <- function(data_dir = default_swiftkey_en_dir()) {
  list(
    blogs   = file.path(data_dir, "en_US.blogs.txt"),
    news    = file.path(data_dir, "en_US.news.txt"),
    twitter = file.path(data_dir, "en_US.twitter.txt")
  )
}

assert_swiftkey_en_present <- function(paths = swiftkey_en_file_paths()) {
  ok <- vapply(paths, file.exists, logical(1))
  if (!all(ok)) {
    miss <- names(paths)[!ok]
    stop(
      "Missing English SwiftKey files under final/en_US/. Unzip Coursera-SwiftKey.zip ",
      "or pass an existing `data_dir`. Missing: ",
      paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}
