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
# TODO: Add data calls in the server script to ensure data is up to date.
#
# -----------------------------------------------------------------------------
server <- function(input, output, session) {
  # Cookies logic -------------------------------------------------------------
  output$cookies_status <- dfeshiny::cookies_banner_server(
    input_cookies = shiny::reactive(input$cookies),
    parent_session = session,
    google_analytics_key = google_analytics_key
  )

  dfeshiny::cookies_panel_server(
    input_cookies = shiny::reactive(input$cookies),
    google_analytics_key = google_analytics_key
  )

  # MP lookup ---------------------------------------------------------------
  updateSelectizeInput(session, "select_postcode", choices = postcode_input_list, server = TRUE)

  output$mpinfo <- renderGovReactable({
    govReactable(mp_data_finder(chosen_postcode = c(input$select_postcode)), bordered = TRUE)
  })

  # footer links -----------------------
  shiny::observeEvent(input$accessibility_statement, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "a11y_panel")
  })

  shiny::observeEvent(input$use_of_cookies, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "cookies_panel_ui")
  })

  shiny::observeEvent(input$privacy_notice, {
    showModal(modalDialog(
      external_link("https://www.gov.uk/government/organisations/department-for-education/about/personal-information-charter", # nolint
        "Privacy notice",
        add_warning = FALSE
      ),
      easyClose = TRUE,
      footer = NULL
    ))

    # JavaScript to auto-click the link and close the modal
    shinyjs::runjs("
      setTimeout(function() {
        var link = document.querySelector('.modal a');
        if (link) {
          link.click();
          setTimeout(function() {
            $('.modal').modal('hide');
          }, 20); // Extra delay to avoid any race conditions
        }
      }, 400);
    ")
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
