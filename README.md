# Data Science Capstone Project

This repository contains work for a Data Science project using the English SwiftKey corpora (blogs, news, and Twitter). The centerpiece is a **next-word prediction** model: given a short phrase, it suggests the most likely following word using Katz backoff over pruned n-gram tables.

[Milestone report](capstone_milestone_report.Rmd)  
*Exploratory analysis: corpus scale, line and token distributions, and simple lexical summaries.*

[Model accuracy report](model_accuracy_report.Rmd)  
*Predictive evaluation: backoff language model, rank-based top-K accuracy, and timing.*

[Next-word prediction app](https://aseemanand.shinyapps.io/Next-Word-Predictor/) *(shinyapps.io name: **Next-Word-Predictor**)*  
*Interactive Shiny app — type a phrase, run **Predict next word**, and inspect ranked predictions, probability bar chart, and cumulative-mass plot.*

[Capstone slides](final_presentation.qmd)  
*Quarto Revealjs deck (overview, Katz backoff, implementation, app walkthrough). Render with `quarto::quarto_render("final_presentation.qmd")` or the RStudio **Render** button.*

---

**Data:** **`Coursera-SwiftKey.zip`** at the repo root, or **`final/en_US/`** extracted, for reports and building **`app/data/lm_app.rds`**. Shiny deploy: **`app/README.md`** and **`Rscript scripts/deploy_shinyapps.R`** from the repo root.
