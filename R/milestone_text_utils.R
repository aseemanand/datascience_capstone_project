# Lightweight token helpers for milestone EDA (base R regexes; no stringr).

count_non_ws_tokens <- function(txt) {
  lengths(regmatches(txt, gregexpr("\\S+", txt, perl = TRUE)))
}

extract_alpha_tokens <- function(txt) {
  txt <- tolower(txt)
  regmatches(txt, gregexpr("[a-z]+(?:'[a-z]+)?", txt, perl = TRUE))
}

expand_word_tokens <- function(line_df) {
  lists <- extract_alpha_tokens(line_df$text)
  len <- lengths(lists)
  keep <- len > 0L
  if (!any(keep)) {
    return(dplyr::tibble(source = character(), token = character()))
  }
  line_df <- line_df[keep, , drop = FALSE]
  lists <- lists[keep]
  len <- len[keep]
  dplyr::tibble(
    source = factor(rep(line_df$source, len), levels = levels(line_df$source)),
    token = unlist(lists, use.names = FALSE)
  )
}
