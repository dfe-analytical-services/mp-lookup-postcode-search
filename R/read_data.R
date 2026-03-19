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

read_postcode_data <- function(file = "data/pcd_to_pcon_lookup_may_24.csv") {
  # Use read.csv to read in data file
  postcode_data <- read.csv(file)

  # Format data file to suitable format (add space before last 3 characters)
  postcode_data <- postcode_data %>%
    dplyr::mutate(
      across(
        .cols = pcd,
        .fns = function(pcd) {
          sub("(.{3})$", " \\1", trimws(pcd))
        }
      )
    ) %>%
    dplyr::rename(
      Postcode = pcd,
      pcon_code = pconcd
    )

  # Return data file
  return(postcode_data)
}

# MP data -----------------------------------------------------------------

read_mp_data <- function(file = "https://raw.githubusercontent.com/dfe-analytical-services/mp-lookup/refs/heads/main/mp_lookup.csv") {
  # Use read.csv to read in data file
  mp_data <- read.csv(file)

  # Format data file to suitable format (select only relevant columns)
  mp_data <- mp_data %>%
    dplyr::select(-c("election_result_summary_2024":"country_code"))

  # Return data file
  return(mp_data)
}
