# Data Science Capstone Project

This repository contains work for a Data Science project using the English SwiftKey corpora (blogs, news, and Twitter). The centerpiece is a **next-word prediction** model: given a short phrase, it suggests the most likely following word using Katz backoff over pruned n-gram tables.

[Milestone report](capstone_milestone_report.Rmd)  
*Exploratory analysis: corpus scale, line and token distributions, and simple lexical summaries.*

[Model accuracy report](model_accuracy_report.Rmd)  
*Predictive evaluation: backoff language model, rank-based top-K accuracy, and timing.*

[Next-word prediction app](https://aseemanand.shinyapps.io/Next-Word-Predictor/) *(shinyapps.io name: **Next-Word-Predictor**)*  
*Interactive Shiny app — type a phrase, run **Predict next word**, and inspect ranked predictions, probability bar chart, and cumulative-mass plot.*

[Project slides](final_presentation.qmd)  
*Quarto Revealjs presentation — goal, Katz backoff, implementation, evaluation, and Shiny app; [view on RPubs](https://rpubs.com/aseem_anand/next-word-predictor-app).*

---

