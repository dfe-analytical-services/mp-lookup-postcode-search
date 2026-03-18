# -----------------------------------------------------------------------------
# Script where we provide functions to read in the data file(s).
#
# IMPORTANT: Data files pushed to GitHub repositories are immediately public.
# You should not be pushing unpublished data to the repository prior to your
# publication date. You should use dummy data or already-published data during
# development of your dashboard.
#
# In order to help prevent unpublished data being accidentally published, the
# template will not let you make a commit if there are unidentified csv, xlsx,
# tex or pdf files contained in your repository. To make a commit, you will need
# to either add the file to .gitignore or add an entry for the file into
# datafiles_log.csv.
# -----------------------------------------------------------------------------

# Post code data ----------------------------------------------------------

read_postcode_data <- function(file = "data/pcd_to_pcon_lookup_may_24.csv") {
  # Use read.csv to read in data file
  postcode_data <- read.csv(file)

  # Format data file to expected format (adding space before last 3 characters)
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
      Postcode = pcd
    )

  return(postcode_data)
}
