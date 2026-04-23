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

  # ---------------------------------------------------------------------------
  # On session start: check whether pins have changed since the process
  # last loaded them. Uses isolate() so this runs imperatively as a
  # one-off side effect rather than creating a reactive dependency loop.
  # Silent from the user's perspective — they just always get current data.
  # ---------------------------------------------------------------------------
  isolate({
    check_and_reload()
  })

  # ---------------------------------------------------------------------------
  # Manual refresh: same check_and_reload(), result surfaced to the user.
  # ---------------------------------------------------------------------------
  refresh_result <- eventReactive(input$refresh_data, {
    check_and_reload()
  })

  output$refresh_status <- renderUI({
    req(input$refresh_data > 0) # nothing shown before first click

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

  # ------------------------------------------------------------------
  # Lookup reactive — reads postcode_rv() and constituency_rv() so it
  # automatically uses the latest data after any reload, without needing
  # to re-run the postcode query itself.
  # ------------------------------------------------------------------
  # TODO: merge with the original code below
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

    list(
      status = "found",
      postcode = pc,
      codes = code,
      data = rows
    )
  })

  observeEvent(input$postcode_search, {
    if (input$postcode_text %in% postcode_input_list) {
      shinyGovstyle::error_off(inputId = "postcode_text")
    } else {
      shinyGovstyle::error_on(
        inputId = "postcode_text",
        error_message = "Please ensure postcode is in the format AB12 3CD."
      )
    }
  })

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
    shiny::bindCache(input$postcode_text) |>
    shiny::bindEvent(input$postcode_search)

  # ------------------------------------------------------------------
  # Freshness panel
  # Takes a reactive dependency on loaded_hashes() so it re-renders
  # automatically whenever a reload updates what is in memory, reflecting
  # the timestamps of the data that is actually being served right now.
  # ------------------------------------------------------------------
  output$pin_freshness <- renderUI({
    loaded_hashes() # reactive dependency — re-renders on any reload

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

  # footer links -----------------------
  shiny::observeEvent(input$accessibility_statement, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "a11y_panel")
  })

  shiny::observeEvent(input$use_of_cookies, {
    shiny::updateTabsetPanel(
      session,
      "footer_links",
      selected = "cookies_panel_ui"
    )
  })

  # Return to MP lookup
  shiny::observeEvent(input$back_to_lookup, {
    shiny::updateTabsetPanel(session, "footer_links", selected = "mp_lookup")
  })
}
