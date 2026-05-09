# Next-word Shiny app (data product)

This folder is a **small interactive client** for the Katz backoff language model defined under `R/` (same core as `model_accuracy_report.Rmd`). It is structured like the reference app in [shelbybachman/data-science-capstone/app](https://github.com/shelbybachman/data-science-capstone/tree/master/app): `global.R` loads data, `ui.R` layout, `server.R` logic.

## What you need

- R with packages: `shiny`, `shinythemes`, `ggplot2`, `scales`, `data.table` (installed automatically on first app load if missing, when your R library is writable).
- English SwiftKey files: `Coursera-SwiftKey.zip` at the **repository root**, or extracted `final/en_US/*.txt`.

**Installing from Terminal (zsh / bash):** do not paste `install.packages(...)` directly into the shell — that is R code. Use:

```bash
R -e 'install.packages(c("shiny", "shinythemes", "ggplot2", "scales", "data.table"), repos = "https://cloud.r-project.org")'
```

## One-time model artifact

The UI reads **`app/data/lm_app.rds`**. Build it from the repo root (tune sample size vs. accuracy):

```r
Rscript scripts/build_app_lm.R           # default 3500 lines per source file
Rscript scripts/build_app_lm.R 8000    # larger / slower / bigger RDS
```

Lower `lines_per_source` shrinks the RDS and speeds up prediction; raising it improves coverage at the cost of size and load time.

## Run locally

From the **repository root**:

```bash
Rscript run_app.R
```

Or in R:

```r
shiny::runApp("app")
```

`global.R` resolves the parent folder as the project root when the app directory is `app/`.

## Deploy publicly (shinyapps.io)

This mirrors [shelbybachman’s hosted app](https://shelbybachman.shinyapps.io/Word-Prediction-App/). **`rsconnect::deployApp('path/to/app')` is not enough for this repo**: the UI sources **`R/source_lm_pipeline.R`** from the **repository root**, so the bundle must include **`app/`**, **`R/`**, root **`app.R`**, and **`app/data/lm_app.rds`**.

### Prerequisite steps

1. **Packages:** `install.packages(c("rsconnect", "shiny", "shinythemes", "ggplot2", "scales", "data.table"))`.
2. **Account:** call **`rsconnect::setAccountInfo(...)`** once per machine if not already loaded from your R environment (never commit tokens).
3. **Model file:** from repo root run `Rscript scripts/build_app_lm.R` so **`app/data/lm_app.rds`** exists.

### Option A — `library(rsconnect)` and `deployApp()` from R

Set **`proj`** to your **clone root** (the folder that contains **`app.R`** and **`R/`**). Do **not** pass only the **`app/`** subdirectory.

```r
library(rsconnect)

proj <- path.expand("~/Documents/datascience_capstone_project")  # <- edit to your path

stopifnot(file.exists(file.path(proj, "app.R")))
stopifnot(file.exists(file.path(proj, "app", "data", "lm_app.rds")))

app_paths <- file.path("app", list.files(file.path(proj, "app"), recursive = TRUE, full.names = FALSE))
r_paths   <- file.path("R", dir(file.path(proj, "R"), pattern = "\\.[rR]$", full.names = FALSE))
bundle    <- unique(c("app.R", app_paths, r_paths))

rsconnect::deployApp(
  appDir         = proj,
  appPrimaryDoc  = "app.R",
  appFiles       = bundle,
  appName        = "SwiftKey-Next-Word",  # optional shinyapps.io URL name
  lint           = FALSE
)
```

**`appFiles`** forces **`lm_app.rds`** into the upload even if **`app/data/*.rds`** is gitignored.

### Option B — helper script from repo root

```bash
Rscript scripts/deploy_shinyapps.R
Rscript scripts/deploy_shinyapps.R SwiftKey-Next-Word
```

Large files are kept off the bundle by **`.rsconnectignore`**; shinyapps.io only needs the RDS model, not the raw SwiftKey corpora.

### Alternate: RStudio “Publish”

Working directory = project root, open **`app.R`**, publish — confirm **`app/data/lm_app.rds`** is listed; otherwise use Option A or B.

## Behavior notes (for end users)

- Input is lowercased and tokenized like the corpus (**letters and apostrophes only**).
- The plot shows **renormalized** probabilities over the displayed top-K so bars sum to 100% for easier reading.
- **Discount D** is the Katz absolute-discount parameter (same meaning as in the accuracy report).

Methodology and evaluation metrics remain documented in **`model_accuracy_report.Rmd`**; this README only describes running and deploying the interactive product.
