# Databricks notebook source
# DBTITLE 1,Description
# MAGIC %md
# MAGIC # Update postcode lookup
# MAGIC
# MAGIC Reads from the postcode lookup and writes the latest postcode-to-constituency lookup to a `pin`, stored in a Volume, ready for reading by the app.
# MAGIC
# MAGIC ## Change detection strategy
# MAGIC
# MAGIC Before writing anything, the notebook checks whether the source Delta table has actually changed since the last pin was written, this saves on unnecessary queries / updates:
# MAGIC
# MAGIC 1. **Delta version (fast, metadata-only)** — query `DESCRIBE HISTORY` for the latest version number. If it matches the version stored in the pin metadata, skip immediately.

# COMMAND ----------

# DBTITLE 1,Shared setup
# MAGIC %run ./_shared_setup

# COMMAND ----------

# DBTITLE 1,Extra dependencies and config
# sparklyr is only needed by this notebook
extra_pkgs <- c("sparklyr")
to_install <- extra_pkgs[!vapply(extra_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(to_install) > 0) install.packages(to_install)
safe_library(extra_pkgs)

UC_TABLE <- "catalog_10_gold.conformed_dimensions.dim_postcode_geography_latest"
PIN_POSTCODE <- "postcode_lookup"

# COMMAND ----------

# DBTITLE 1,Fetch and pin postcode lookup
# Connect to Spark and get the current Delta table version
sc <- suppressWarnings(spark_connect(method = "databricks"))

current_delta_version <- suppressWarnings(
  sparklyr::sdf_sql(
    sc,
    glue::glue("DESCRIBE HISTORY {UC_TABLE} LIMIT 1")
  ) |>
    collect()
) |>
  dplyr::pull(version) |>
  as.character()

message("Current Delta version : ", current_delta_version)

pinned_delta_version <- read_pin_meta_field(board, PIN_POSTCODE, "delta_version")
message("Pinned Delta version  : ", pinned_delta_version %||% "<none>")

needs_update <- is.null(pinned_delta_version) || current_delta_version != pinned_delta_version

if (needs_update) {
  message("→ Delta table has changed (or pin is new). Update required.")
} else {
  message("✓ postcode_lookup is current. Skipping re-pin.")
}

# COMMAND ----------

# DBTITLE 1,Fetch and pin postcode lookup
if (needs_update) {
  # Read the two-column lookup from Unity Catalog
  postcode_df <- dplyr::tbl(sc, UC_TABLE) |>
    select(postcode, pcon_code = parliamentary_constituency_2024_code) |>
    collect()

  # Sort by postcode for fast in-app lookup
  postcode_df <- dplyr::arrange(postcode_df, postcode)

  # Validate, write to parquet, and pin (with temp-file cleanup)
  pin_parquet(
    board         = board,
    df            = postcode_df,
    pin_name      = PIN_POSTCODE,
    title         = "Postcode to constituency code lookup",
    description   = glue::glue("Delta version {current_delta_version}, pinned at {Sys.time()}"),
    metadata      = list(delta_version = current_delta_version),
    expected_cols = c("postcode", "pcon_code")
  )

  message("\u2713 postcode_lookup updated to Delta version ", current_delta_version)
}

spark_disconnect(sc)
