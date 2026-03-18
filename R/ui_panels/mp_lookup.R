# Function to generate MP information table -------------------------------

mp_data_finder <- function(chosen_postcode) {
  data <- mp_data %>%
    dplyr::filter(pcd == paste(chosen_postcode)) %>%
    rename("Postcode" := pcd)
  return(data)
}
