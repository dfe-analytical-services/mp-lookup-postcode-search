# -----------------------------------------------------------------------------
# This is the server file.
#
# Use it to create interactive elements like tables, charts and text for your
# app.
#
# Anything you create in the server file won't appear in your app until you call
# it in the UI file. This server script gives examples of plots and value boxes
#
# There are many other elements you can add in too, and you can play around with
# their reactivity. The "outputs" section of the shiny cheatsheet has a few
# examples of render calls you can use:
# https://shiny.rstudio.com/images/shiny-cheatsheet.pdf
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# -----------------------------------------------------------------------------
server <- function(input, output, session) {
  # Load data -----------------------------------------------------------------
  mp_data <- read_mp_data()

  # Cookies logic -------------------------------------------------------------
  observeEvent(input$cookieAccept, {
    shinyjs::show(id = "cookieAcceptDiv")
    shinyjs::hide(id = "cookieMain")
  })

  observeEvent(input$cookieReject, {
    shinyjs::show(id = "cookieRejectDiv")
    shinyjs::hide(id = "cookieMain")
  })

  observeEvent(input$hideAccept, {
    shinyjs::toggle(id = "cookieDiv")
  })

  observeEvent(input$hideReject, {
    shinyjs::toggle(id = "cookieDiv")
  })

  observeEvent(input$cookieLink, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "cookies_panel_ui")
  })

  # MP lookup -----------------------------------------------------------------
  # Set table output as hidden when app first loads
  shinyjs::hideElement(id = "table_output")

  # Add error message for postcodes that do not appear in the reference list
  observeEvent(input$postcode_search, {
    if (input$postcode_text %in% postcode_input_list) {
      shinyGovstyle::error_off(inputId = "postcode_text")
      shinyjs::showElement(id = "table_output")
    } else {
      shinyGovstyle::error_on(
        inputId = "postcode_text",
        error_message = "Postcode not found. Enter a full UK postcode."
      )
      shinyjs::hideElement(id = "table_output")
    }
  })

  output$mpinfo <- renderGovReactable({
    shinyGovstyle::govReactable(
      output_table <- postcode_data |>
        dplyr::filter(Postcode == paste(input$postcode_text)) |>
        dplyr::left_join(mp_data, by = "pcon_code") |>
        dplyr::rename(
          Party = party_text,
          Name = display_as,
          "Full Title" = full_title,
          "Member Email" = member_email,
          Constituency = pcon_name
        ) |>
        select(-c("pcon_code", "member_id"))
    )
  }) |>
    shiny::bindCache(input$postcode_text) |>
    shiny::bindEvent(input$postcode_search)

  # footer links -----------------------
  shiny::observeEvent(input$accessibility_statement, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "a11y_panel")
  })

  shiny::observeEvent(input$use_of_cookies, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "cookies_panel_ui")
  })

  # Return to MP lookup
  shiny::observeEvent(input$back_to_lookup, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "mp_lookup")
  })

  # Stop app ------------------------------------------------------------------
  session$onSessionEnded(function() {
    stopApp()
  })
}
