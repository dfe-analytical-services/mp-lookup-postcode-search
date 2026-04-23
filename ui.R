# -----------------------------------------------------------------------------
# This is the ui file. Use it to call elements created in your server file into
# the app, and define where they are placed, and define any user inputs.
#
# Other elements like charts, navigation bars etc. are completely up to you to
# decide what goes in. However, every element should meet accessibility
# requirements and user needs.
#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# The documentation for GOV.UK components can be found at:
#
#    https://github.com/moj-analytical-services/shinyGovstyle
#
# -----------------------------------------------------------------------------
ui <- function(input, output, session) {
  bslib::page_fluid(
    # Set application metadata ------------------------------------------------
    tags$head(HTML("<title>Department for Education (DfE) MP lookup</title>")),
    tags$head(tags$link(rel = "shortcut icon", href = "dfefavicon.png")),
    use_shiny_title(),
    useShinyjs(),
    tags$html(lang = "en"),
    # Add meta description for search engines
    meta() |>
      meta_general(
        application_name = "Department for Education (DfE) Shiny MP lookup",
        description = "Department for Education (DfE) MP lookup",
        robots = "index,follow",
        generator = "R-Shiny",
        subject = "stats development",
        rating = "General",
        referrer = "no-referrer"
      ),

    # Custom disconnect function ----------------------------------------------
    # Variables used here are set in the global.R file
    dfeshiny::custom_disconnect_message(
      links = sites_list,
      publication_name = parent_pub_name,
      publication_link = parent_publication
    ),

    # Load javascript dependencies --------------------------------------------
    shinyjs::useShinyjs(),

    # Cookies -----------------------------------------------------------------
    # Setting up cookie consent based on a cookie recording the consent:
    shinyGovstyle::cookieBanner("Department for Education (DfE) MP lookup"),

    # Skip_to_main -------------------------------------------------------------
    # Add a 'Skip to main content' link for keyboard users to bypass navigation.
    # It stays hidden unless focussed via tabbing.
    shinyGovstyle::skip_to_main(),

    # Google analytics --------------------------------------------------------
    tags$head(includeHTML(("google-analytics.html"))),

    # Header ------------------------------------------------------------------
    shinyGovstyle::full_width_overrides(),
    shinyGovstyle::header(
      org_name = "Department for Education (DfE)",
      service_name = "Postcode MP lookup"
    ),

    # Beta banner -------------------------------------------------------------
    shinyGovstyle::banner(
      "beta banner",
      "Beta",
      "This dashboard is in beta phase and we are still reviewing performance and reliability.
      If you have any questions or feedback, please contact
      <a href='mailto:HoP.statistics@education.gov.uk'>HoP.statistics@education.gov.uk</a>."
    ),

    # Tab panels --------------------------------------------------------------
    shiny::tabsetPanel(
      id = "footer_links",
      selected = "mp_lookup",
      type = "hidden",

      # MP lookup page
      shiny::tabPanel(
        value = "mp_lookup",
        "MP lookup",
        shinyGovstyle::gov_main_layout(
          shinyGovstyle::gov_row(
            column(
              10,
              shinyGovstyle::heading_text("MP Lookup"),
              shinyGovstyle::gov_text(
                "Please search a postcode to retrieve up-to-date MP information for that area."
              ),
              shinyGovstyle::gov_text(
                "This tool uses the ",
                shinyGovstyle::external_link(
                  href = "https://github.com/dfe-analytical-services/mp-lookup", "DfE's MP Lookup"
                ),
                " which updates from the ",
                shinyGovstyle::external_link(
                  href = "https://data.parliament.uk/membersdataplatform/default.aspx", "UK Parliament API"
                ),
                " daily."
              ),
              div(
                shinyGovstyle::text_Input(
                  inputId = "postcode_text",
                  label = "Enter a postcode",
                  hint_label = "Please enter a valid UK postcode",
                  width = 5,
                  error = TRUE
                ),
                shinyGovstyle::button_Input(
                  inputId = "postcode_search",
                  label = "Search"
                )
              ),
              # TODO: Explore data download or copy to clipboard outputs
              div(
                id = "table_output",
                govReactableOutput(
                  "mpinfo",
                  # TODO: Make caption reactive
                  caption = "MP information for chosen postcode.",
                  caption_size = "s"
                )
              )
            )
          )
        )
      ),

      # Accessibility page
      shiny::tabPanel(
        value = "a11y_panel",
        "Accessibility",
        shinyGovstyle::gov_main_layout(
          shinyGovstyle::gov_row(
            column(
              10,
              shinyGovstyle::backlink_Input("back_to_lookup"),
              dfeshiny::a11y_panel(
                dashboard_title = site_title,
                dashboard_url = site_primary,
                date_tested = "12th March 2024",
                date_prepared = "1st July 2024",
                date_reviewed = "1st July 2024",
                issues_contact = "explore.statistics@education.gov.uk",
                non_accessible_components = c("List non-accessible components here"),
                specific_issues = c("List specific issues here")
              )
            )
          )
        )
      ),

      # Cookies page
      shiny::tabPanel(
        value = "cookies_panel_ui",
        "Cookies",
        shinyGovstyle::gov_main_layout(
          shinyGovstyle::gov_row(
            column(
              10,
              shinyGovstyle::backlink_Input("back_to_lookup"),
              cookies_panel_ui(google_analytics_key = google_analytics_key)
            )
          )
        )
      )
    ),

    # Footer ------------------------------------------------------------------
    shinyGovstyle::footer(
      full = TRUE,
      links = c(
        "Accessibility statement",
        "Use of cookies",
        "Privacy notice" = "https://www.gov.uk/government/organisations/department-for-education/about/personal-information-charter" # nolint
      )
    )
  )
}
