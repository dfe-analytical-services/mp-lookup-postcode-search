# Function to generate MP information table -------------------------------

mp_data_finder <- function(chosen_postcode) {
  data <- postcode_data %>%
    dplyr::filter(Postcode == paste(chosen_postcode)) %>%
    return(data)
}
