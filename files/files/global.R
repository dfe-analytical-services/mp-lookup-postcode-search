# -----------------------------------------------------------------------------
# This is the global file.
#
# Use it to store functions, library calls, source files etc.
#
# Moving these out of the server file and into here improves performance as the
# global file is run only once when the app launches and stays consistent
# across users whereas the server and UI files are constantly interacting and
# responsive to user input.
#
# Library calls ---------------------------------------------------------------
shhh <- suppressPackageStartupMessages # It's a library, so shhh!

# Core shiny and R packages
shhh(library(shiny))
shhh(library(bslib))
shhh(library(rstudioapi))

# Custom packages
shhh(library(dfeR))
shhh(library(dfeshiny))
shhh(library(shinyGovstyle))

# Creating tables
shhh(library(htmltools))
shhh(library(reactable))

# Reading files
shhh(library(arrow))
shhh(library(data.table))
shhh(library(pins))

# Data and string manipulation
shhh(library(dplyr))

# Shiny extensions
shhh(library(shinyjs))
shhh(library(tools))
shhh(library(shinytitle))
shhh(library(xfun))
shhh(library(metathis))
shhh(library(shinyalert))

# Dependencies needed for testing or CI but not for the app -------------------
# Including them here keeps them in renv but avoids the app needlessly loading
# them, saving on load time.
if (FALSE) {
  shhh(library(shinytest2))
  shhh(library(chromote))
  shhh(library(testthat))
}

# Set global variables --------------------------------------------------------
site_title <- "Department for Education (DfE) MP lookup" # name of app
parent_pub_name <- "MP lookup" # name of source publication
parent_publication <- # link to source publication
  "https://github.com/dfe-analytical-services/mp-lookup"

# Set the URLs that the site will be published to
site_primary <- "https://department-for-education.shinyapps.io/dfe-mp-lookup-postcode-search/"

# Combine URLs into list for disconnect function
# We can add further mirrors where necessary. Each one can generally handle
# about 2,500 users simultaneously
sites_list <- c(site_primary)

# Set the key for Google Analytics tracking
google_analytics_key <- "Z967JJVQQX"

# End of global variables -----------------------------------------------------

# Read in data ----------------------------------------------------------------
# Two pins are saved:
# - postcode to constituency lookup (postcode_data)
# - constituency to MP lookup (constituency_dt)
#
# constituency_dt supports returning 1–n rows with identical syntax:
# single row : constituency_dt[.("E14000639")]
# multi-row : constituency_dt[.(c("E14000639", "E14000640"))]
#
# Data freshness strategy:
# - On process startup, both pins are loaded into shared reactive values.
# - On each new session start, pin hashes are checked against what is
# currently loaded. If either has changed, the in-memory structures are
# silently reloaded before the user can interact.
# - A manual "Refresh data" button lets users trigger the same check and
# reload on demand, with a visible confirmation of whether data changed.
# - No polling — checks only happen on session start and on button click.
#
# Required env vars (.Renviron locally or as env vars on Posit Connect):
# DATABRICKS_TOKEN — PAT (or CONNECT_DATABRICKS_TOKEN)
# DATABRICKS_HOST — e.g. https://adb-<id>.azuredatabricks.net
# =============================================================================
BOARD_PATH <- "/Volumes/catalog_40_copper_statistics_services/postcode_mp/pins"

board <- board_databricks(
  folder_url = BOARD_PATH,
  versioned = TRUE,
  cache = NULL
)

load_postcode_lookup <- function() {
  tbl <- pin_download(board, "postcode_lookup") |> read_parquet()
  vec <- setNames(tbl$constituency_code, tbl$postcode)
  rm(tbl)
  vec
}

load_constituency_dt <- function() {
  dt <- pin_download(board, "constituency_data") |>
    read_parquet() |>
    as.data.table()
  setkey(dt, constituency_code)
  dt
}

# -----------------------------------------------------------------------------
# Process-level startup
#
# postcode_rv : reactiveVal — named character vector
# names = postcode (e.g. "SW1A1AA")
# values = code (e.g. "E14000639")
#
# constituency_rv : reactiveVal — keyed data.table, key = constituency_code
#
# loaded_hashes : reactiveVal — named character vector recording the pin
# hashes that correspond to what is currently in memory.
# Each session compares live pin hashes against this to
# detect whether a re-pin has occurred since the last load.
#
# All three are defined outside server() so they are process-level —
# shared across all sessions within this worker. The first session to
# detect a change reloads the data for every subsequent session in the
# same worker process.
# -----------------------------------------------------------------------------
message("Loading pins into memory...")

postcode_rv <- reactiveVal(load_postcode_lookup())
constituency_rv <- reactiveVal(load_constituency_dt())

loaded_hashes <- reactiveVal(c(
  postcode = pin_meta(board, "postcode_lookup")$pin_hash,
  constituency = pin_meta(board, "constituency_data")$pin_hash
))

message("Pins loaded. App ready.")

# -----------------------------------------------------------------------------
# Helper: normalise postcode input
# -----------------------------------------------------------------------------
normalise_postcode <- function(x) {
  toupper(gsub("\\s+", "", trimws(x)))
}

# -----------------------------------------------------------------------------
# Shared reload function
#
# Compares the live pin hashes from the board against loaded_hashes().
# Re-downloads and rebuilds only the structures whose hash has changed.
# Updates loaded_hashes() so subsequent callers see the new baseline.
#
# Returns TRUE if anything was reloaded, FALSE if everything was current.
# Safe to call from multiple sessions — reactiveVals are reference objects
# so mutations are immediately visible to all sessions in this process.
# -----------------------------------------------------------------------------
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

# TODO: Extract lists for use in drop downs -----------------------------------------
postcode_input_list <- postcode_data |>
  dplyr::pull(Postcode)
