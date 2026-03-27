# Function to generate MP information table -------------------------------

pconsearch <- dplyr::left_join(postcode_data, mp_data)

mp_data_finder <- function(chosen_postcode) {
  data <- pconsearch %>%
    dplyr::filter(Postcode == paste(chosen_postcode)) %>%
    dplyr::rename(Party = party_text, Name = display_as, "Full Title" = full_title, "Member Email" = member_email, Constituency = pcon_name) %>%
    select(-pcon_code, -member_id) %>%
    return(data)
}
