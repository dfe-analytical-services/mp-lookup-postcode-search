server <- function(input, output, session) {
  # --- App state ---
  state <- reactiveValues(
    status = "idle", # "idle" | "found" | "not_found"
    postcode = NA_character_, # normalised postcode the user searched
    row = NULL # one-row data.frame to render, or NULL
  )

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
    bindCache(state$postcode)

  # --- Footer links ---
  observeEvent(input$accessibility_statement, {
    updateTabsetPanel(session, "footer_links", selected = "a11y_panel")
  })
  observeEvent(input$back_to_lookup, {
    updateTabsetPanel(session, "footer_links", selected = "mp_lookup")
  })
}
