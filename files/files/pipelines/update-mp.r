# Databricks notebook source
# DBTITLE 1,Cell 1
# MAGIC %md
# MAGIC # Update MP information
# MAGIC
# MAGIC Takes from https://github.com/dfe-analytical-services/mp-lookup/blob/main/mp_lookup.csv and then writes the latest to a `pin`, which is stored in a Volume, ready for reading by the app. 
# MAGIC
# MAGIC ## Change detection strategy
# MAGIC
# MAGIC Before writing anything, the notebook checks whether the source has actually changed since the last pin was written:
# MAGIC
# MAGIC 1. **Commit SHA (fast, metadata-only)** — query the GitHub Commits API for the latest commit SHA on the file. If it matches the SHA stored in the pin metadata, skip immediately.
# MAGIC 2. **Content hash (guards against false positives)** — if the commit SHA has changed, download the CSV and compute its SHA-256 hash. Compare against the hash in the pin metadata. If the content is identical (e.g. a commit that only touched other files), skip the re-pin.

# COMMAND ----------

# DBTITLE 1,Shared setup
# MAGIC %run ./_shared_setup

# COMMAND ----------

# DBTITLE 1,Extra dependencies and config
# httr2 and digest are only needed by this notebook
extra_pkgs <- c("httr2", "digest")
to_install <- extra_pkgs[!vapply(extra_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(to_install) > 0) install.packages(to_install)
safe_library(extra_pkgs)

GITHUB_RAW_URL   <- "https://raw.githubusercontent.com/dfe-analytical-services/mp-lookup/refs/heads/main/mp_lookup.csv"
GITHUB_API_URL   <- "https://api.github.com/repos/dfe-analytical-services/mp-lookup/commits?path=mp_lookup.csv&per_page=1"
PIN_CONSTITUENCY <- "constituency_data"

# COMMAND ----------

# DBTITLE 1,Fetch and pin constituency data
# Fetch the latest commit SHA for the file from the GitHub Commits API.
# This is fast (metadata only) and tells us immediately if the file
# has changed without downloading the full CSV.
commits_resp <- request(GITHUB_API_URL) |>
  req_headers(
    Accept       = "application/vnd.github+json",
    `User-Agent` = "dfe-mp-lookup-pipeline"
  ) |>
  req_retry(max_tries = 3) |>
  req_perform()

latest_commit_sha <- resp_body_json(commits_resp)[[1]]$sha
message("Latest GitHub commit SHA : ", latest_commit_sha)

pinned_commit_sha <- read_pin_meta_field(board, PIN_CONSTITUENCY, "github_commit_sha")
message("Pinned  GitHub commit SHA: ", pinned_commit_sha %||% "<none>")

if (is.null(pinned_commit_sha) || latest_commit_sha != pinned_commit_sha) {

  message("\u2192 Commit SHA changed (or pin is new). Downloading CSV...")

  # Download the full CSV
  raw_csv <- request(GITHUB_RAW_URL) |>
    req_headers(`User-Agent` = "dfe-mp-lookup-pipeline") |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_string()

  # Secondary check: skip re-pin if content is identical despite new commit
  content_hash <- digest::digest(raw_csv, algo = "sha256")
  pinned_content_hash <- read_pin_meta_field(board, PIN_CONSTITUENCY, "content_hash")

  if (!is.null(pinned_content_hash) && content_hash == pinned_content_hash) {

    message("\u2713 Content unchanged despite new commit SHA. Skipping re-pin.")

  } else {

    constituency_df <- arrow::read_csv_arrow(charToRaw(raw_csv))

    # Sort by primary key for fast in-app lookup
    constituency_df <- arrange(constituency_df, pcon_code)

    # Validate, write to parquet, and pin (with temp-file cleanup)
    pin_parquet(
      board         = board,
      df            = constituency_df,
      pin_name      = PIN_CONSTITUENCY,
      title         = "Constituency reference data",
      description   = glue::glue("Commit {substr(latest_commit_sha, 1, 7)}, pinned at {Sys.time()}"),
      metadata      = list(
        github_commit_sha = latest_commit_sha,
        content_hash      = content_hash
      ),
      expected_cols = c("pcon_code")
    )

    message("\u2713 constituency_data updated to commit ", substr(latest_commit_sha, 1, 7))
  }

} else {
  message("\u2713 constituency_data is current. Skipping re-pin.")
}
