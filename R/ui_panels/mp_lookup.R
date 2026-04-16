# Function to generate MP information table -------------------------------

mp_data_finder <- function(chosen_postcode) {
  data <- postcode_data |>
    dplyr::filter(Postcode == paste(chosen_postcode)) |>
    dplyr::left_join(mp_data, by = "pcon_code") |>
    dplyr::rename(
      Party = party_text,
      Name = display_as,
      "Full Title" = full_title,
      "Member Email" = member_email,
      Constituency = pcon_name
    ) |>
    select(-pcon_code, -member_id)
}
