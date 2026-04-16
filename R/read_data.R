# -----------------------------------------------------------------------------
# Script where we provide functions to read in the data file(s).
#
# IMPORTANT: Data files pushed to GitHub repositories are immediately public.
# You should not be pushing unpublished data to the repository prior to your
# publication date. You should use dummy data or already-published data during
# development of your dashboard.
#
# -----------------------------------------------------------------------------

# Post code data ----------------------------------------------------------

# TODO: Explore what geography data HoC use in their MP information tool
# TODO: Explore databricks postcode data, brought in by API.
read_postcode_data <- function(file = "data/pcd_to_pcon_lookup_may_24.csv") {
  # Read file
  postcode_data <- read.csv(file)

  # Format data
  postcode_data <- postcode_data |>
    mutate(
      # Remove ALL whitespace from postcode
      pcd = gsub("\\s+", "", pcd),

      # Then reinsert a space before the last 3 characters (standard UK format)
      pcd = sub("(.{3})$", " \\1", pcd)
    ) |>
    rename(
      Postcode  = pcd,
      pcon_code = pconcd
    )

  return(postcode_data)
}

# MP data -----------------------------------------------------------------

read_mp_data <- function(file = "https://raw.githubusercontent.com/dfe-analytical-services/mp-lookup/refs/heads/main/mp_lookup.csv") {
  # Use read.csv to read in data file
  mp_data <- read.csv(file)

  # Format data file to suitable format (select only relevant columns)
  mp_data <- mp_data |>
    dplyr::select(-c("election_result_summary_2024":"country_code"))

  # Return data file
  return(mp_data)
}
