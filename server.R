server <- function(input, output, session) {
  # --- Cookie banners ---
  output$cookies_status <- dfeshiny::cookies_banner_server(
    input_cookies = reactive(input$cookies),
    parent_session = session,
    google_analytics_key = google_analytics_key
  )
  dfeshiny::cookies_panel_server(
    input_cookies = reactive(input$cookies),
    google_analytics_key = google_analytics_key
  )

  # --- Data freshness: check pins on session start ---
  isolate(check_and_reload())

  # --- Manual refresh button ---
  refresh_result <- eventReactive(input$refresh_data, check_and_reload())
  output$refresh_status <- renderUI({
    req(input$refresh_data > 0)
    if (refresh_result()) {
      div(
        class = "alert alert-success",
        style = "margin-top:8px; padding:6px 10px; font-size:0.85em;",
        icon("circle-check"),
        " Data reloaded."
      )
    } else {
      div(
        class = "alert alert-info",
        style = "margin-top:8px; padding:6px 10px; font-size:0.85em;",
        icon("circle-info"),
        " Already up to date."
      )
    }
  })

  # --- Postcode lookup logic ---
  lookup_result <- eventReactive(input$postcode_search, {
    req(nchar(trimws(input$postcode)) > 0)
    pc <- normalise_postcode(input$postcode)
    code <- postcode_rv()[[pc]]
    if (is.null(code) || is.na(code)) {
      return(list(
        status = "not_found",
        postcode = pc,
        codes = NULL,
        data = NULL
      ))
    }
    rows <- constituency_rv()[.(code), nomatch = NULL]
    if (nrow(rows) == 0L) {
      return(list(
        status = "code_missing",
        postcode = pc,
        codes = code,
        data = NULL
      ))
    }
    list(status = "found", postcode = pc, codes = code, data = rows)
  })

  # --- Input validation ---
  observeEvent(input$postcode_search, {
    # Could add a more robust validation here if needed
    if (nchar(normalise_postcode(input$postcode_text)) >= 5) {
      shinyGovstyle::error_off(inputId = "postcode_text")
    } else {
      shinyGovstyle::error_on(
        inputId = "postcode_text",
        error_message = "Please ensure postcode is in the format AB12 3CD."
      )
    }
  })

  # --- MP info table ---
  mp_data <- read_mp_data()
  output$mpinfo <- renderGovReactable({
    res <- lookup_result()
    table <- res$data |>
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
    shinyGovstyle::govReactable(table)
  }) |>
    bindCache(input$postcode_text) |>
    bindEvent(input$postcode_search)

  # --- Data freshness panel ---
  output$pin_freshness <- renderUI({
    loaded_hashes()
    pc_meta <- pin_meta(board, "postcode_lookup")
    con_meta <- pin_meta(board, "constituency_data")
    tagList(
      tags$small(
        tags$b("Data in memory"),
        br(),
        "Postcode lookup: ",
        format(pc_meta$created, "%d %b %Y %H:%M UTC"),
        br(),
        "Constituency data: ",
        format(con_meta$created, "%d %b %Y %H:%M UTC"),
        br(),
        if (!is.null(con_meta$user$github_blob_sha)) {
          paste0("GitHub SHA: ", substr(con_meta$user$github_blob_sha, 1, 7))
        }
      )
    )
  })

  # --- Footer links ---
  observeEvent(input$accessibility_statement, {
    updateTabsetPanel(session, "footer_links", selected = "a11y_panel")
  })
  observeEvent(input$use_of_cookies, {
    updateTabsetPanel(session, "footer_links", selected = "cookies_panel_ui")
  })
  observeEvent(input$back_to_lookup, {
    updateTabsetPanel(session, "footer_links", selected = "mp_lookup")
  })
}
