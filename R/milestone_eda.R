# Tables and ggplot2 figures for milestone report body.

summarize_line_samples <- function(samples) {
  dplyr::group_by(samples, .data$source) %>%
    dplyr::summarise(
      lines_sampled = dplyr::n(),
      mean_words = mean(.data$words),
      median_words = stats::median(.data$words),
      sd_words = stats::sd(.data$words),
      mean_chars = mean(.data$chars),
      q90_words = stats::quantile(.data$words, 0.90),
      pct_empty = mean(.data$words == 0) * 100,
      .groups = "drop"
    )
}

top_tokens_by_source <- function(samples, k = 15L) {
  tok <- dplyr::bind_rows(expand_word_tokens(dplyr::filter(samples, .data$words > 0)))
  tok %>%
    dplyr::count(.data$source, .data$token, sort = TRUE) %>%
    dplyr::group_by(.data$source) %>%
    dplyr::slice_head(n = k) %>%
    dplyr::ungroup()
}

plot_words_per_line_density <- function(samples) {
  ggplot2::ggplot(samples, ggplot2::aes(x = .data$words)) +
    ggplot2::geom_histogram(
      ggplot2::aes(y = ggplot2::after_stat(count / sum(count))),
      bins = 60,
      boundary = 0,
      colour = "white"
    ) +
    ggplot2::facet_wrap(~source, ncol = 1, scales = "free_y") +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 0.1)) +
    ggplot2::coord_cartesian(xlim = c(0, stats::quantile(samples$words, 0.995))) +
    ggplot2::labs(
      x = "Words per line (non-whitespace tokens)",
      y = "Share of sampled lines",
      title = "Words-per-line distributions (truncated x-axis at ~99.5th percentile)"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}

plot_words_per_line_box <- function(samples) {
  ggplot2::ggplot(samples, ggplot2::aes(x = .data$source, y = .data$words, fill = .data$source)) +
    ggplot2::geom_boxplot(outlier.alpha = 0.15, show.legend = FALSE) +
    ggplot2::coord_cartesian(ylim = c(0, stats::quantile(samples$words, 0.99))) +
    ggplot2::labs(
      x = NULL,
      y = "Words per line",
      title = "Spread of line lengths by source (y truncated near 99th percentile)"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}

plot_chars_per_line_density <- function(samples) {
  ggplot2::ggplot(samples, ggplot2::aes(x = .data$chars)) +
    ggplot2::geom_histogram(
      ggplot2::aes(y = ggplot2::after_stat(count / sum(count))),
      bins = 60,
      boundary = 0,
      colour = "white"
    ) +
    ggplot2::facet_wrap(~source, ncol = 1, scales = "free_y") +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 0.1)) +
    ggplot2::coord_cartesian(xlim = c(0, stats::quantile(samples$chars, 0.995))) +
    ggplot2::labs(
      x = "Characters per line",
      y = "Share of sampled lines",
      title = "Character-count distributions (truncated for readability)"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}

plot_top_tokens_faceted <- function(top_tokens) {
  ggplot2::ggplot(top_tokens, ggplot2::aes(x = stats::reorder(.data$token, .data$n), y = .data$n)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::facet_wrap(~source, ncol = 1, scales = "free_y") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      x = NULL,
      y = "Count in sample",
      title = "Top token counts by source (head sample only)"
    ) +
    ggplot2::theme_minimal(base_size = 11)
}
