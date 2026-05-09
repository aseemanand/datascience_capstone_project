fluidPage(
  theme = shinytheme("flatly"),
  tags$head(
    tags$title("Next-word prediction (Katz backoff)"),
    tags$style(
      HTML(
        ".well { background:#fafafa; border-radius:8px; }
        textarea.form-control { min-height: 88px; }"
      )
    )
  ),
  titlePanel("SwiftKey capstone — next-word predictor"),
  uiOutput("model_banner"),
  sidebarLayout(
    sidebarPanel(
      tags$p(
        "Enter ",
        tags$strong("one or more words"),
        ". The model ranks next tokens using the same Katz backoff tables as ",
        tags$code("model_accuracy_report.Rmd"),
        " (pruned training recommended for speed/size)."
      ),
      textAreaInput(
        "phrase",
        "Phrase / n-gram prefix",
        value = "the rest of the",
        placeholder = "e.g. thanks for the",
        resize = "vertical"
      ),
      sliderInput(
        "discount",
        "Katz absolute discount D",
        min = 0.5,
        max = 1,
        value = 0.75,
        step = 0.05
      ),
      sliderInput(
        "top_k",
        "How many candidates to rank",
        min = 5,
        max = 50,
        value = 25,
        step = 5
      ),
      actionButton("go", "Predict next word", class = "btn-primary btn-lg", width = "100%"),
      width = 4
    ),
    mainPanel(
      verbatimTextOutput("ctx_note"),
      uiOutput("top1"),
      h4("Top predictions (rank & Katz score)"),
      tableOutput("rank_table"),
      h4("Probability visualization"),
      plotOutput("bar_top", width = "100%"),
      h4("Cumulative mass over ranks"),
      plotOutput("cumulative", width = "100%"),
      tags$hr(),
      tags$p(
        class = "text-muted small",
        "Scores are Katz backoff probabilities over an approximate candidate set (continuations seen in training plus frequent unigrams); ",
        "bars renormalize across displayed top-K for readability."
      ),
      width = 8
    )
  )
)
