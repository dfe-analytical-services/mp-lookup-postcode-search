#!/usr/bin/env Rscript
cat("Running commit hooks...", fill = TRUE)
shhh <- suppressPackageStartupMessages # It's a library, so shhh!
shhh(library(dplyr))
shhh(library(xfun))
shhh(library(dfeshiny))

message("\n")

message("1. Checking Google Analytics tag...\n")

if (grepl("G-Z967JJVQQX", htmltools::includeHTML(("google-analytics.html"))) &
  !(toupper(Sys.getenv("USERNAME")) %in% c("CFOSTER4", "CRACE", "LSELBY", "RBIELBY", "JMACHIN"))) {
  message("...cleaning out the template's Google Analytics tag.")
  gsub_file("google-analytics.html", pattern = "G-Z967JJVQQX", replacement = "G-XXXXXXXXXX")
  gsub_file("ui.R", pattern = "Z967JJVQQX", replacement = "XXXXXXXXXX")
  system2(command = "git", args = c("add", "google-analytics.html"))
} else {
  message("...all good!")
}

message("\n")

message("2. Checking code styling...\n")
style_output <- eval(styler::style_dir()$changed)
if (any(style_output)) {
  message("Warning: Code failed styling checks.
  \n`styler::style_dir()` has been run for you.
  \nPlease check your files and dashboard still work.
  \nThen re-stage and try committing again.")
  quit(save = "no", status = 1, runLast = FALSE)
} else {
  message("...code styling checks passed")
  message("\n")
}

# End of hooks
