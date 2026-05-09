function(input, output, session) {
  output$model_banner <- renderUI({
    if (!LM_READY) {
      return(
        div(
          class = "alert alert-warning",
          tags$p(
            strong("Model file missing."),
            " From the repo root run ",
            tags$code("Rscript scripts/build_app_lm.R"),
            " (see ",
            tags$code("app/README.md"),
            ")."
          )
        )
      )
    }
    div(
      class = "alert alert-secondary",
      style = "padding:10px 12px;",
      tags$p(
        strong("Loaded model:"),
        " ",
        sprintf("%s stored n-gram rows", format(LM_META$n_parameters %||% lm_n_parameters(LM_OBJ), big.mark = ",")),
        " · vocab ",
        format(LM_META$vocab_size %||% LM_OBJ$vocab_size, big.mark = ","),
        if (!is.null(LM_META$lines_per_source)) {
          sprintf(" · trained on %s lines/source (%s lines)", LM_META$lines_per_source, format(LM_META$n_lines, big.mark = ","))
        } else {
          ""
        }
      )
    )
  })

  preds <- eventReactive(input$go, {
    req(LM_READY)
    validate(need(nchar(trimws(input$phrase)) > 0L, "Type a phrase and click Predict."))
    tok <- normalize_input_tokens(input$phrase)
    validate(
      need(length(tok) > 0L, "No letter-only tokens found (letters and apostrophes only, matching the corpus tokenizer).")
    )
    dt <- predict_next_ranked(
      LM_OBJ,
      tok,
      discount = input$discount,
      top_k = input$top_k
    )
    list(full_token_count = length(tok), table = dt)
  })

  output$ctx_note <- renderText({
    if (input$go == 0L) {
      return("Click Predict to rank next words.")
    }
    req(LM_READY)
    p <- preds()
    req(p)
    n <- p$full_token_count
    sprintf(
      "Conditioning on your full phrase (%d token%s); quadgrams use the last three words, with backoff to shorter histories.",
      n,
      if (n == 1L) "" else "s"
    )
  })

  output$top1 <- renderUI({
    req(LM_READY)
    req(input$go > 0L)
    p <- preds()
    req(p)
    validate(need(nrow(p$table) > 0L, "No candidates — context may be out of vocabulary."))
    w <- p$table$word[[1L]]
    tags$h2(style = "margin-top:12px;", HTML(paste0("Best guess: ", tags$strong(w))))
  })

  output$rank_table <- renderTable(
    {
      req(LM_READY)
      req(input$go > 0L)
      p <- preds()
      req(p)
      validate(need(nrow(p$table) > 0L, character()))
      head(p$table, min(15L, nrow(p$table)))
    },
    striped = TRUE,
    hover = TRUE,
    digits = 4
  )

  output$bar_top <- renderPlot(
    {
      req(LM_READY)
      req(input$go > 0L)
      p <- preds()
      req(p)
      validate(need(nrow(p$table) > 0L, NULL))
      show_n <- min(input$top_k, nrow(p$table))
      df <- head(p$table, show_n)
      df$prob <- df$score / sum(df$score)
      ggplot(df, aes(x = reorder(word, prob), y = prob)) +
        geom_col(fill = "#5b8c85", colour = "#222222", linewidth = 0.2) +
        coord_flip() +
        scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
        labs(x = NULL, y = "Normalized share of top-K scores", title = "Next-word distribution (top predictions)") +
        theme_minimal(base_size = 13) +
        theme(
          panel.grid.major.y = element_blank(),
          plot.title = element_text(face = "bold")
        )
    },
    height = function() {
      if (!LM_READY || !isolate(input$go)) {
        return(120)
      }
      p <- isolate(preds())
      if (is.null(p) || !nrow(p$table)) {
        return(120)
      }
      show_n <- min(isolate(input$top_k), nrow(p$table))
      max(280, show_n * 18)
    }
  )

  output$cumulative <- renderPlot(
    {
      req(LM_READY)
      req(input$go > 0L)
      p <- preds()
      req(p)
      validate(need(nrow(p$table) > 0L, NULL))
      show_n <- min(input$top_k, nrow(p$table))
      df <- head(p$table, show_n)
      df$prob <- df$score / sum(df$score)
      df$cum <- cumsum(df$prob)
      df$rank <- seq_len(nrow(df))
      ggplot(df, aes(x = rank, y = cum)) +
        geom_line(colour = "#c07858", linewidth = 1) +
        geom_point(size = 1.6, colour = "#333333") +
        scale_y_continuous(labels = percent_format(accuracy = 1)) +
        labs(
          x = "Rank",
          y = "Cumulative probability mass",
          title = "How quickly probability concentrates (SwiftKey-style insight)"
        ) +
        theme_minimal(base_size = 13) +
        theme(plot.title = element_text(face = "bold"))
    },
    height = 260
  )
}
