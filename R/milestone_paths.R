# Paths and validation for English SwiftKey corpora (Coursera Capstone).
# Prefers reading from Coursera-SwiftKey.zip at the project root when present;
# otherwise uses extracted files under final/en_US/.

default_swiftkey_en_dir <- function(root = ".") {
  normalizePath(file.path(root, "final", "en_US"), mustWork = FALSE)
}

default_swiftkey_zip_path <- function(root = ".") {
  normalizePath(file.path(root, "Coursera-SwiftKey.zip"), mustWork = FALSE)
}

swiftkey_zip_inner_paths <- function() {
  list(
    blogs   = "final/en_US/en_US.blogs.txt",
    news    = "final/en_US/en_US.news.txt",
    twitter = "final/en_US/en_US.twitter.txt"
  )
}

swiftkey_en_file_paths <- function(data_dir = default_swiftkey_en_dir()) {
  list(
    blogs   = file.path(data_dir, "en_US.blogs.txt"),
    news    = file.path(data_dir, "en_US.news.txt"),
    twitter = file.path(data_dir, "en_US.twitter.txt")
  )
}

#' @param root Project directory containing either `Coursera-SwiftKey.zip` or `final/en_US/*.txt`.
resolve_swiftkey_en <- function(root = ".") {
  zp <- default_swiftkey_zip_path(root)
  if (file.exists(zp)) {
    list(mode = "zip", zip_path = zp, members = swiftkey_zip_inner_paths())
  } else {
    list(mode = "dir", paths = swiftkey_en_file_paths(default_swiftkey_en_dir(root)))
  }
}

assert_swiftkey_en_present <- function(paths = swiftkey_en_file_paths()) {
  ok <- vapply(paths, file.exists, logical(1))
  if (!all(ok)) {
    miss <- names(paths)[!ok]
    stop(
      "Missing English SwiftKey files under final/en_US/. Add Coursera-SwiftKey.zip ",
      "at the project root or extract the archive. Missing: ",
      paste(miss, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(paths)
}

assert_swiftkey_data_available <- function(spec = resolve_swiftkey_en()) {
  if (spec$mode == "zip") {
    if (!file.exists(spec$zip_path)) {
      stop("Zip not found: ", spec$zip_path, call. = FALSE)
    }
    invisible(spec)
  } else {
    assert_swiftkey_en_present(spec$paths)
  }
}
