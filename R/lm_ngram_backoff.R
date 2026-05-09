# N-gram language model with Katz backoff (absolute discounting).
# Probability: P(w|h) = max(c(h,w)-D,0)/c(h) + (1 - sum_disc(h)) * P(w|h'),
# where h' drops the earliest word of h (recursive backoff to unigrams).
# Depends on data.table (loaded by source_lm_pipeline.R) and extract_alpha_tokens().

tokenize_lines_lm <- function(text_lines) {
  lapply(text_lines, function(line) {
    unlist(extract_alpha_tokens(line))
  })
}

aggregate_windows_dt <- function(tokens_vec, order) {
  L <- length(tokens_vec)
  if (L < order) {
    return(data.table())
  }
  idx <- seq_len(L - order + 1L)
  switch(
    as.character(order),
    "1" = data.table(w1 = tokens_vec),
    "2" = data.table(w1 = tokens_vec[idx], w2 = tokens_vec[idx + 1L]),
    "3" = data.table(
      w1 = tokens_vec[idx],
      w2 = tokens_vec[idx + 1L],
      w3 = tokens_vec[idx + 2L]
    ),
    "4" = data.table(
      w1 = tokens_vec[idx],
      w2 = tokens_vec[idx + 1L],
      w3 = tokens_vec[idx + 2L],
      w4 = tokens_vec[idx + 3L]
    ),
    data.table()
  )
}

tokens_list_to_counts <- function(tokens_list, order, min_freq = 1L) {
  parts <- lapply(tokens_list, aggregate_windows_dt, order = order)
  if (!length(parts)) {
    return(data.table())
  }
  dt <- rbindlist(parts)
  if (!nrow(dt)) {
    return(dt)
  }
  nm <- paste0("w", seq_len(order))
  dt <- dt[, .N, by = nm]
  if (min_freq > 1L) {
    dt <- dt[N >= min_freq]
  }
  dt[]
}

#' Build keyed count tables for uni–quadgrams from tokenized training sentences.
build_ngram_lm <- function(
    tokens_list,
    min_freq_uni = 1L,
    min_freq_bi = 1L,
    min_freq_tri = 1L,
    min_freq_quad = 1L
) {
  uni <- tokens_list_to_counts(tokens_list, 1L, min_freq_uni)
  bi <- tokens_list_to_counts(tokens_list, 2L, min_freq_bi)
  tri <- tokens_list_to_counts(tokens_list, 3L, min_freq_tri)
  quad <- tokens_list_to_counts(tokens_list, 4L, min_freq_quad)

  if (nrow(uni)) {
    setkeyv(uni, "w1")
  }
  if (nrow(bi)) {
    setkeyv(bi, c("w1", "w2"))
  }
  if (nrow(tri)) {
    setkeyv(tri, c("w1", "w2", "w3"))
  }
  if (nrow(quad)) {
    setkeyv(quad, c("w1", "w2", "w3", "w4"))
  }

  total_uni <- if (nrow(uni)) {
    sum(uni$N)
  } else {
    0
  }

  list(
    uni = uni,
    bi = bi,
    tri = tri,
    quad = quad,
    total_uni = total_uni,
    vocab_size = if (nrow(uni)) uniqueN(uni$w1) else 0L,
    min_freq = c(
      uni = min_freq_uni,
      bi = min_freq_bi,
      tri = min_freq_tri,
      quad = min_freq_quad
    )
  )
}

lm_n_parameters <- function(lm) {
  nrow(lm$uni) + nrow(lm$bi) + nrow(lm$tri) + nrow(lm$quad)
}

quad_joint <- function(lm, a, b, c, w) {
  if (!nrow(lm$quad)) {
    return(0)
  }
  hit <- lm$quad[list(a, b, c, w), nomatch = NA]
  if (is.na(hit$N[1L])) {
    return(0)
  }
  as.numeric(hit$N[1L])
}

quad_prefix_den <- function(lm, a, b, c) {
  if (!nrow(lm$quad)) {
    return(0)
  }
  rows <- lm$quad[list(a, b, c), nomatch = NULL]
  if (!nrow(rows)) {
    return(0)
  }
  sum(rows$N)
}

tri_joint <- function(lm, a, b, w) {
  if (!nrow(lm$tri)) {
    return(0)
  }
  hit <- lm$tri[list(a, b, w), nomatch = NA]
  if (is.na(hit$N[1L])) {
    return(0)
  }
  as.numeric(hit$N[1L])
}

tri_prefix_den <- function(lm, a, b) {
  if (!nrow(lm$tri)) {
    return(0)
  }
  rows <- lm$tri[list(a, b), nomatch = NULL]
  if (!nrow(rows)) {
    return(0)
  }
  sum(rows$N)
}

bi_joint <- function(lm, a, w) {
  if (!nrow(lm$bi)) {
    return(0)
  }
  hit <- lm$bi[list(a, w), nomatch = NA]
  if (is.na(hit$N[1L])) {
    return(0)
  }
  as.numeric(hit$N[1L])
}

bi_prefix_den <- function(lm, a) {
  if (!nrow(lm$bi)) {
    return(0)
  }
  rows <- lm$bi[list(a), nomatch = NULL]
  if (!nrow(rows)) {
    return(0)
  }
  sum(rows$N)
}

uni_prob <- function(lm, w) {
  if (!nrow(lm$uni) || lm$total_uni <= 0) {
    return(1e-12)
  }
  hit <- lm$uni[list(w), nomatch = NA]
  if (is.na(hit$N[1L])) {
    return(1e-12)
  }
  max(as.numeric(hit$N[1L]) / lm$total_uni, 1e-12)
}

#' Katz backoff probability for word `w` given context tokens `prev_words`
#' (discount D on each observed continuation count).
katz_prob_word <- function(w, prev_words, lm, discount = 0.75) {
  D <- discount
  k <- length(prev_words)
  if (k == 0L) {
    return(uni_prob(lm, w))
  }

  if (k >= 3L) {
    a <- prev_words[k - 2L]
    b <- prev_words[k - 1L]
    c <- prev_words[k]
    rows <- lm$quad[list(a, b, c), nomatch = NULL]
    den <- quad_prefix_den(lm, a, b, c)
    if (!nrow(rows) || den <= 0) {
      return(katz_prob_word(w, prev_words[-1L], lm, D))
    }
    sum_disc <- sum(pmax(rows$N - D, 0)) / den
    beta <- max(1 - sum_disc, 1e-15)
    cw <- quad_joint(lm, a, b, c, w)
    direct <- if (cw > 0) max(cw - D, 0) / den else 0
    return(direct + beta * katz_prob_word(w, prev_words[-1L], lm, D))
  }

  if (k == 2L) {
    a <- prev_words[1L]
    b <- prev_words[2L]
    rows <- lm$tri[list(a, b), nomatch = NULL]
    den <- tri_prefix_den(lm, a, b)
    if (!nrow(rows) || den <= 0) {
      return(katz_prob_word(w, prev_words[-1L], lm, D))
    }
    sum_disc <- sum(pmax(rows$N - D, 0)) / den
    beta <- max(1 - sum_disc, 1e-15)
    cw <- tri_joint(lm, a, b, w)
    direct <- if (cw > 0) max(cw - D, 0) / den else 0
    return(direct + beta * katz_prob_word(w, prev_words[-1L], lm, D))
  }

  if (k == 1L) {
    a <- prev_words[1L]
    rows <- lm$bi[list(a), nomatch = NULL]
    den <- bi_prefix_den(lm, a)
    if (!nrow(rows) || den <= 0) {
      return(katz_prob_word(w, integer(0), lm, D))
    }
    sum_disc <- sum(pmax(rows$N - D, 0)) / den
    beta <- max(1 - sum_disc, 1e-15)
    cw <- bi_joint(lm, a, w)
    direct <- if (cw > 0) max(cw - D, 0) / den else 0
    return(direct + beta * katz_prob_word(w, integer(0), lm, D))
  }

  uni_prob(lm, w)
}

gather_candidate_words <- function(prev_words, lm, max_candidates = 400L, uni_extra = 120L) {
  k <- length(prev_words)
  cand <- character()

  if (k >= 3L) {
    a <- prev_words[k - 2L]
    b <- prev_words[k - 1L]
    c <- prev_words[k]
    rows <- lm$quad[list(a, b, c), nomatch = NULL]
    if (nrow(rows)) {
      cand <- c(cand, rows$w4)
    }
  }
  if (k >= 2L) {
    b <- prev_words[k - 1L]
    c <- prev_words[k]
    rows <- lm$tri[list(b, c), nomatch = NULL]
    if (nrow(rows)) {
      cand <- c(cand, rows$w3)
    }
  }
  if (k >= 1L) {
    c <- prev_words[k]
    rows <- lm$bi[list(c), nomatch = NULL]
    if (nrow(rows)) {
      cand <- c(cand, rows$w2)
    }
  }

  if (nrow(lm$uni)) {
    topu <- head(lm$uni[order(-N)], uni_extra)$w1
    cand <- c(cand, topu)
  }

  cand <- unique(cand)
  if (length(cand) > max_candidates) {
    cand <- cand[seq_len(max_candidates)]
  }
  cand
}

score_candidates_katz <- function(lm, prev_words, cand, discount = 0.75) {
  if (!length(cand)) {
    return(data.table(word = character(), score = numeric()))
  }
  sc <- vapply(cand, katz_prob_word, numeric(1), prev_words = prev_words, lm = lm, discount = discount)
  data.table(word = cand, score = sc)[order(-score)]
}

#' Top-ranked next-word candidates by Katz backoff probability (approximate over candidates).
predict_next_ranked <- function(lm, prev_words, discount = 0.75, top_k = 50L) {
  if (!length(prev_words)) {
    return(data.table(word = character(), score = numeric()))
  }
  cand <- gather_candidate_words(prev_words, lm)
  if (!length(cand)) {
    return(data.table(word = character(), score = numeric()))
  }
  dt <- score_candidates_katz(lm, prev_words, cand, discount)
  head(dt, top_k)
}
