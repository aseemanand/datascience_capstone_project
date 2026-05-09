# Data Science Capstone Project (SwiftKey)

This repository contains work for a Coursera-style Data Science capstone using the English SwiftKey corpora (blogs, news, and Twitter). The centerpiece is a **next-word prediction** model: given a short phrase, it suggests the most likely following word using Katz backoff over pruned n-gram tables.

[Milestone report](capstone_milestone_report.Rmd)  
*Exploratory analysis: corpus scale, line and token distributions, and simple lexical summaries.*

[Model accuracy report](model_accuracy_report.Rmd)  
*Predictive evaluation: backoff language model, Bachman-style accuracy, and timing.*

[Next-word prediction app](https://aseemanand.shinyapps.io/SwiftKey-Next-Word/)  
*Interactive Shiny app — type a phrase and inspect ranked predictions and plots.*

---

**Data:** place **`Coursera-SwiftKey.zip`** at the repo root, or extract English files under **`final/en_US/`**, to knit the reports locally. Implementation notes for the Shiny bundle live in **`app/README.md`**.
