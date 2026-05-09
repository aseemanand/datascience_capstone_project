# Data Science Capstone (SwiftKey English)

Coursera-style capstone using the English SwiftKey corpora (blogs, news, Twitter).

## Reports (knit from project root)

| Document | Purpose |
|----------|---------|
| **`capstone_milestone_report.Rmd`** | EDA: corpus scale, line/token distributions, simple lexical summaries (reads zip or `final/en_US/`). |
| **`model_accuracy_report.Rmd`** | Predictive model: Katz backoff n-grams, Bachman-style accuracy, timing; uses `data.table`. |

```r
rmarkdown::render("capstone_milestone_report.Rmd")
rmarkdown::render("model_accuracy_report.Rmd")
```

## Data layout

- **`Coursera-SwiftKey.zip`** at the repo root (recommended), or **`final/en_US/*.txt`** after unzip.
- Large artifacts are listed in **`.gitignore`** — keep the zip locally and share reports only if desired.

## R modules

- **`R/source_milestone_modules.R`** — paths, sampling, EDA plots (`capstone_milestone_report.Rmd`).
- **`R/source_lm_pipeline.R`** — tokenization, `build_ngram_lm`, Katz prediction, Bachman evaluation (`model_accuracy_report.Rmd`).

## Packages

**Milestone:** `dplyr`, `ggplot2`, `scales`, `knitr`, `rmarkdown`.

**Model accuracy:** above plus **`data.table`** (installed automatically in the report chunk if missing).
