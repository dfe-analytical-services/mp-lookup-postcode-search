# -----------------------------------------------------------------------------
# GLOBALS: Libraries, constants, data loading, helpers
# -----------------------------------------------------------------------------

shhh <- suppressPackageStartupMessages

# Core packages
shhh(library(shiny))
shhh(library(bslib))
shhh(library(rstudioapi))
# Custom UI packages
shhh(library(dfeR))
shhh(library(dfeshiny))
shhh(library(shinyGovstyle))
# Tables and HTML
shhh(library(htmltools))
shhh(library(reactable))
# Data IO
shhh(library(arrow))
shhh(library(data.table))
shhh(library(pins))
# Data manipulation
shhh(library(dplyr))
# Shiny extensions
shhh(library(shinyjs))
shhh(library(tools))
shhh(library(shinytitle))
shhh(library(xfun))
shhh(library(metathis))
shhh(library(shinyalert))

# Test/CI-only dependencies (not loaded in app)
if (FALSE) {
  shhh(library(shinytest2))
  shhh(library(chromote))
  shhh(library(testthat))
}

# ---- Constants ----
site_title <- "Department for Education (DfE) MP lookup"
parent_pub_name <- "MP lookup"
parent_publication <- "https://github.com/dfe-analytical-services/mp-lookup"
site_primary <- "https://department-for-education.shinyapps.io/dfe-mp-lookup-postcode-search/"
sites_list <- c(site_primary)
google_analytics_key <- "Z967JJVQQX"

# ---- Data pins ----
BOARD_PATH <- "/Volumes/catalog_40_copper_statistics_services/postcode_mp/pins"
board <- board_databricks(
  folder_url = BOARD_PATH,
  versioned = TRUE,
  cache = NULL
)

load_postcode_lookup <- function() {
  tbl <- pin_download(board, "postcode_lookup") |> read_parquet()
  setNames(tbl$pcon_code, tbl$postcode)
}

load_constituency_dt <- function() {
  dt <- pin_download(board, "constituency_data") |>
    read_parquet() |>
    as.data.table()
  setkey(dt, pcon_code)
  dt
}

# ---- Process-level shared reactives ----
message("Loading pins into memory...")
postcode_rv <- reactiveVal(load_postcode_lookup())
constituency_rv <- reactiveVal(load_constituency_dt())
loaded_hashes <- reactiveVal(c(
  postcode = pin_meta(board, "postcode_lookup")$pin_hash,
  constituency = pin_meta(board, "constituency_data")$pin_hash
))
message("Pins loaded. App ready.")

# ---- Helpers ----
normalise_postcode <- function(x) toupper(gsub("\\s+", "", trimws(x)))

check_and_reload <- function() {
  current_pc_hash <- pin_meta(board, "postcode_lookup")$pin_hash
  current_con_hash <- pin_meta(board, "constituency_data")$pin_hash
  hashes <- loaded_hashes()
  reloaded <- FALSE
  if (!identical(current_pc_hash, hashes[["postcode"]])) {
    message("postcode_lookup pin changed — reloading at ", Sys.time())
    postcode_rv(load_postcode_lookup())
    reloaded <- TRUE
  }
  if (!identical(current_con_hash, hashes[["constituency"]])) {
    message("constituency_data pin changed — reloading at ", Sys.time())
    constituency_rv(load_constituency_dt())
    reloaded <- TRUE
  }
  if (reloaded) {
    loaded_hashes(c(
      postcode = current_pc_hash,
      constituency = current_con_hash
    ))
  }
  reloaded
}
