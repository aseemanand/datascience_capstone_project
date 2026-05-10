# Rank-based next-word evaluation: top-K list scoring for held-out n-gram instances.

#' Tabulate trigram types (bigram start -> third word) with frequencies on tokenized test text.
test_trigram_type_frequencies <- function(tokens_list) {
  parts <- lapply(tokens_list, function(t) {
    if (length(t) < 3L) {
      return(NULL)
    }
    i <- seq.int(3L, length(t))
    data.table::data.table(
      start = paste(t[i - 2L], t[i - 1L]),
      end = t[i]
    )
  })
  parts <- parts[!vapply(parts, is.null, logical(1))]
  if (!length(parts)) {
    return(data.table::data.table(start = character(), end = character(), frequency = integer()))
  }
  dt <- data.table::rbindlist(parts)
  dt[, .(frequency = .N), by = .(start, end)]
}

#' Tabulate quadgram types (trigram start -> fourth word).
test_quadgram_type_frequencies <- function(tokens_list) {
  parts <- lapply(tokens_list, function(t) {
    if (length(t) < 4L) {
      return(NULL)
    }
    i <- seq.int(4L, length(t))
    data.table::data.table(
      start = paste(t[i - 3L], t[i - 2L], t[i - 1L]),
      end = t[i]
    )
  })
  parts <- parts[!vapply(parts, is.null, logical(1))]
  if (!length(parts)) {
    return(data.table::data.table(start = character(), end = character(), frequency = integer()))
  }
  dt <- data.table::rbindlist(parts)
  dt[, .(frequency = .N), by = .(start, end)]
}

#' Sample rows for high-frequency (> hi_cut) and mid-frequency (between lo_cut exclusive and hi_low exclusive) bins.
sample_ngram_eval_pairs <- function(
    freq_dt,
    n_samples = 25L,
    hi_cut = 50L,
    hi_low = 25L,
    lo_hi = 10L,
    seed = 1L
) {
  set.seed(seed)
  hi <- freq_dt[frequency > hi_cut]
  lo <- freq_dt[frequency > lo_hi & frequency < hi_low]
  n_hi <- min(as.integer(n_samples), nrow(hi))
  n_lo <- min(as.integer(n_samples), nrow(lo))
  list(
    high = if (n_hi > 0L) hi[sample.int(nrow(hi), n_hi)] else hi,
    low = if (n_lo > 0L) lo[sample.int(nrow(lo), n_lo)] else lo,
    n_high_requested = n_hi,
    n_low_requested = n_lo
  )
}

#' Token sequence from a space-separated prefix (matches stored `start` strings).
start_text_to_tokens <- function(start_text) {
  unlist(strsplit(trimws(start_text), "\\s+"))
}

#' Next-word predictions as a data frame with columns `end`, `score`, `rank`.
predict_next_word <- function(
    start_text,
    lm,
    katz_discount = 0.75,
    n_to_return = 50L
) {
  tok <- start_text_to_tokens(start_text)
  if (!length(tok)) {
    return(data.frame(end = character(), score = numeric(), rank = integer()))
  }
  pr <- predict_next_ranked(lm, tok, discount = katz_discount, top_k = n_to_return)
  if (!nrow(pr)) {
    return(data.frame(end = character(), score = numeric(), rank = integer()))
  }
  data.frame(
    end = pr$word,
    score = pr$score,
    rank = seq_len(nrow(pr)),
    stringsAsFactors = FALSE
  )
}

#' Rank-based accuracy: top-1 -> 1; rank r in top-K -> (K - r + 1) / K; absent -> 0.
evaluate_accuracy_ranked <- function(
    start_text,
    true_end,
    lm,
    katz_discount = 0.75,
    n_to_return = 50L
) {
  results <- predict_next_word(start_text, lm, katz_discount, n_to_return)
  if (!nrow(results)) {
    return(0)
  }
  y <- true_end
  hit_rows <- which(results$end == y)
  if (!length(hit_rows)) {
    return(0)
  }
  r <- as.integer(results$rank[hit_rows[1L]])
  if (r == 1L) {
    return(1)
  }
  (as.numeric(n_to_return) - as.numeric(r) + 1) / as.numeric(n_to_return)
}

#' Fixed evaluation instances: sampled high/low-frequency 3- and 4-gram types from held-out text.
build_rank_eval_instances <- function(
    test_tokens,
    n_samples = 25L,
    seed = 17L
) {
  tri_freq <- test_trigram_type_frequencies(test_tokens)
  quad_freq <- test_quadgram_type_frequencies(test_tokens)

  tri_s <- sample_ngram_eval_pairs(tri_freq, n_samples = n_samples, seed = seed)
  quad_s <- sample_ngram_eval_pairs(quad_freq, n_samples = n_samples, seed = seed + 1L)

  add_part <- function(dt, ngram_lab, bin_lab) {
    if (!nrow(dt)) {
      return(NULL)
    }
    data.frame(
      start = dt$start,
      end = dt$end,
      freq_test = dt$frequency,
      ngram = ngram_lab,
      freq_level = bin_lab,
      stringsAsFactors = FALSE
    )
  }

  parts <- Filter(Negate(is.null), list(
    add_part(quad_s$high, "4-gram", "high frequency"),
    add_part(tri_s$high, "3-gram", "high frequency"),
    add_part(quad_s$low, "4-gram", "low frequency"),
    add_part(tri_s$low, "3-gram", "low frequency")
  ))

  if (!length(parts)) {
    return(data.frame())
  }
  out <- do.call(rbind, parts)
  out$indx <- seq_len(nrow(out))
  out
}

#' Score fixed instances with one trained model + Katz discount `katz_discount`.
evaluate_lm_on_instances <- function(
    instances,
    lm,
    katz_discount = 0.75,
    n_to_return = 50L
) {
  if (!nrow(instances)) {
    return(instances)
  }
  acc <- vapply(
    seq_len(nrow(instances)),
    function(i) {
      evaluate_accuracy_ranked(
        instances$start[i],
        instances$end[i],
        lm,
        katz_discount,
        n_to_return
      )
    },
    numeric(1)
  )
  instances$accuracy <- acc
  instances
}

#' Time predictions given parallel character vectors `starts` and `ends`.
time_prediction_pairs <- function(starts, ends, lm, katz_discount = 0.75, n_to_return = 50L) {
  if (!length(starts)) {
    return(list(elapsed_sec = NA_real_, n = 0L))
  }
  tm <- system.time({
    for (i in seq_along(starts)) {
      predict_next_word(starts[i], lm, katz_discount, n_to_return)
    }
  })
  list(elapsed_sec = as.numeric(tm["elapsed"]), n = length(starts))
}

#' Split raw text lines into tokenized train/test lists (via tokenize_lines_lm).
train_test_tokens_from_lines <- function(
    text_lines,
    train_frac = 0.85,
    seed = 42L
) {
  set.seed(seed)
  n <- length(text_lines)
  ord <- sample.int(n)
  cut <- max(1L, floor(train_frac * n))
  train_ix <- ord[seq_len(cut)]
  test_ix <- ord[(cut + 1L):n]
  tr <- tokenize_lines_lm(text_lines[train_ix])
  te <- tokenize_lines_lm(text_lines[test_ix])
  list(train = tr, test = te)
}
