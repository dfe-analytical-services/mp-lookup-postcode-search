server <- function(input, output, session) {
  # --- Data freshness: check pins on session start ---
  isolate(check_and_reload())

  # --- App state ---
  state <- reactiveValues(
    status = "idle", # "idle" | "found" | "not_found"
    postcode = NA_character_, # normalised postcode the user searched
    row = NULL, # one-row data.frame to render, or NULL
    refresh_msg = NULL # "reloaded" | "uptodate" | NULL
  )

  # --- Manual refresh button ---
  observeEvent(input$refresh_data, {
    reloaded <- check_and_reload()
    state$refresh_msg <- if (reloaded) "reloaded" else "uptodate"
  })

  output$refresh_status <- renderUI({
    req(state$refresh_msg)
    variant <- switch(state$refresh_msg,
      reloaded = list(
        class = "alert-success",
        icon = "circle-check",
        text = " Data reloaded."
      ),
      uptodate = list(
        class = "alert-info",
        icon = "circle-info",
        text = " Already up to date."
      )
    )
    div(
      class = paste("alert", variant$class),
      style = "margin-top:8px; padding:6px 10px; font-size:0.85em;",
      icon(variant$icon),
      variant$text
    )
  })

  # --- Postcode search: validate + lookup in one place ---
  observeEvent(input$postcode_search, {
    show_not_found <- function(pc = NA_character_, msg) {
      state$status <- "not_found"
      state$postcode <- pc
      state$row <- NULL
      shinyGovstyle::error_on(inputId = "postcode_text", error_message = msg)
      shinyjs::hideElement(id = "table_output")
    }

    raw <- input$postcode_text %||% ""
    if (nchar(trimws(raw)) == 0) {
      return(show_not_found(msg = "Enter a full UK postcode."))
    }

    pc <- normalise_postcode(raw)
    code <- postcode_rv()[pc]
    if (is.na(code)) {
      return(show_not_found(
        pc,
        "Postcode not found. Enter a full UK postcode."
      ))
    }
    code <- unname(code)

    rows <- constituency_rv()[.(code), nomatch = NULL]
    if (nrow(rows) == 0L) {
      return(show_not_found(
        pc,
        "Postcode not found. Enter a full UK postcode."
      ))
    }

    rows$Postcode <- pc
    state$status <- "found"
    state$postcode <- pc
    state$row <- rows
    shinyGovstyle::error_off(inputId = "postcode_text")
    shinyjs::showElement(id = "table_output")
  })

  # --- MP info table ---
  output$mpinfo <- renderGovReactable({
    req(state$status == "found", state$row)
    tbl <- state$row |>
      dplyr::rename(
        Party = party_text,
        Name = display_as,
        `Full Title` = full_title,
        `Member Email` = member_email,
        Constituency = pcon_name
      ) |>
      dplyr::select(-dplyr::any_of(c("pcon_code", "member_id")))
    shinyGovstyle::govReactable(tbl)
  }) |>
    bindCache(state$postcode, loaded_hashes())

  # --- Data freshness panel ---
  output$pin_freshness <- renderUI({
    loaded_hashes()
    pc_meta <- pins::pin_meta(board, "postcode_lookup")
    con_meta <- pins::pin_meta(board, "constituency_data")
    tagList(
      tags$small(
        tags$b("Latest pin version"),
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
  observeEvent(input$back_to_lookup, {
    updateTabsetPanel(session, "footer_links", selected = "mp_lookup")
  })
}
