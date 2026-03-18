# -----------------------------------------------------------------------------
# This is the helper file, filled with lots of helpful functions!
#
# It is commonly used as an R script to store custom functions used through the
# app to keep the rest of the app code easier to read.
# -----------------------------------------------------------------------------

#' Standardise internal links ---------------------------------------------
#'
#' This function generates a link to an internal tabPanel (target_link),
#' with the link text specified in "link_text"
#' The following is required in the server.R script
#'
#'   # navigation link within text --------------------------------------------
#' observeEvent(input$nav_link, {
#'   shiny::updateTabsetPanel(session, "navlistPanel", selected = input$nav_link)
#' })
#'
#' The target location could be changed to a different UI element by
#' changing the "navlistPanel" element of the server code

in_line_nav_link <- function(link_text, target_link) {
  HTML(paste0(
    "<a href='#' onclick=\"Shiny.setInputValue('nav_link', '",
    target_link,
    "', {priority: 'event'});\">",
    link_text,
    "</a>"
  ))
}
