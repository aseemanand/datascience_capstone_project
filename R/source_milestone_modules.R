# Source in dependency order for capstone_milestone_report.Rmd.
# Working directory should be the project root (where final/en_US lives).

source(file.path("R", "milestone_paths.R"), encoding = "UTF-8")
source(file.path("R", "milestone_text_utils.R"), encoding = "UTF-8")
source(file.path("R", "milestone_load_samples.R"), encoding = "UTF-8")
source(file.path("R", "milestone_eda.R"), encoding = "UTF-8")
