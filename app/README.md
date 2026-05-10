# Next-word Shiny app (data product)

This folder is a **small interactive client** for the Katz backoff language model defined under `R/` (same core as `model_accuracy_report.Rmd`). 

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

## Deploying publicly (shinyapps.io)


### Prerequisite steps

1. **Packages:** `install.packages(c("rsconnect", "shiny", "shinythemes", "ggplot2", "scales", "data.table"))`.
2. **Account:** call **`rsconnect::setAccountInfo(...)`** once per machine if not already loaded from your R environment (never commit tokens).
3. **Model file:** **`app/data/lm_app.rds`** is gitignored; create it with `Rscript scripts/build_app_lm.R` (needs SwiftKey data). The **deploy script runs that build automatically** if the file is missing.

**If you use `stopifnot(file.exists(..., "lm_app.rds"))` in R and it fails:** your working directory is wrong or the file was never built. Set **`proj`** to the **repository root** (the folder that contains **`app.R`**), then either run `Rscript scripts/build_app_lm.R` or:

```r
proj <- normalizePath("path/to/datascience_capstone_project")
system2("Rscript", file.path(proj, "scripts", "build_app_lm.R"), wait = TRUE)
stopifnot(file.exists(file.path(proj, "app", "data", "lm_app.rds")))
```

From the **repository root** (the folder that contains **`app.R`** and **`R/`**):

```bash
Rscript scripts/deploy_shinyapps.R
```

That script calls **`rsconnect::deployApp`** with the correct **`appFiles`** list (including **`app/data/lm_app.rds`** when gitignored), **`appPrimaryDoc = "app.R"`**, and **`appName = "Next-Word-Predictor"`** → `https://aseemanand.shinyapps.io/Next-Word-Predictor/`.

**From R:** `setwd("<repo root>")` then `system2("Rscript", "scripts/deploy_shinyapps.R", wait = TRUE)`.

**Not** `deployApp("app/")` alone: the UI sources **`R/`** from the repo root, so the bundle must be built from the root (as the script does).

Large paths are excluded via **`.rsconnectignore`**; the server only needs the pre-built RDS, not the raw corpora.

**RStudio:** working directory = project root, open **`app.R`**, publish — ensure **`app/data/lm_app.rds`** is in the file list, or use the script above.

## Behavior notes (for end users)

- Input is lowercased and tokenized like the corpus (**letters and apostrophes only**).
- The plot shows **renormalized** probabilities over the displayed top-K so bars sum to 100% for easier reading.
- **Discount D** is the Katz absolute-discount parameter (same meaning as in the accuracy report).

Methodology and evaluation metrics remain documented in **`model_accuracy_report.Rmd`**; this README only describes running and deploying the interactive product.
