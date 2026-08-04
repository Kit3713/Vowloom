import "@hotwired/turbo-rails"

const answerValues = (form, questionId) => {
  const inputs = form.querySelectorAll(`[data-questionnaire-question-input="${questionId}"]`)

  return Array.from(inputs).flatMap((input) => {
    if (input.disabled) return []
    if (input instanceof HTMLSelectElement && input.multiple) {
      return Array.from(input.selectedOptions).map((option) => option.value)
    }
    if ((input.type === "checkbox" || input.type === "radio") && !input.checked) return []

    return input.value ? [input.value] : []
  })
}

const updateConditionalQuestions = (form) => {
  form.querySelectorAll("[data-questionnaire-conditional-question-id]").forEach((section) => {
    const sourceQuestionId = section.dataset.questionnaireConditionalQuestionId
    const expectedValue = section.dataset.questionnaireConditionalValue
    const visible = answerValues(form, sourceQuestionId).includes(expectedValue)

    section.hidden = !visible
    section.setAttribute("aria-hidden", (!visible).toString())
    section.querySelectorAll("input, select, textarea").forEach((input) => {
      input.disabled = !visible
    })
  })
}

const bindQuestionnaireForms = () => {
  document.querySelectorAll("[data-questionnaire-form]").forEach((form) => {
    if (form.dataset.questionnaireConditionalBound) return

    form.dataset.questionnaireConditionalBound = "true"
    form.addEventListener("input", () => updateConditionalQuestions(form))
    form.addEventListener("change", () => updateConditionalQuestions(form))
    updateConditionalQuestions(form)
  })
}

document.addEventListener("turbo:load", bindQuestionnaireForms)

const calendarDateFromIso = (value) => {
  if (!value) return null

  const [year, month, day] = value.split("-").map(Number)
  return new Date(Date.UTC(year, month - 1, day))
}

const calendarIsoDate = (date) => [
  date.getUTCFullYear(),
  String(date.getUTCMonth() + 1).padStart(2, "0"),
  String(date.getUTCDate()).padStart(2, "0")
].join("-")

const calendarDisplayDate = (date) => new Intl.DateTimeFormat(undefined, {
  dateStyle: "long",
  timeZone: "UTC"
}).format(date)

const calendarToday = () => {
  const today = new Date()
  return new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()))
}

const bindWeddingCalendars = () => {
  document.querySelectorAll("[data-wedding-calendar]").forEach((calendar) => {
    if (calendar.dataset.calendarBound) return

    const valueInput = calendar.querySelector("[data-calendar-value]")
    const openButton = calendar.querySelector("[data-calendar-open]")
    const dialog = calendar.querySelector("[data-calendar-dialog]")
    const monthSelect = calendar.querySelector("[data-calendar-month]")
    const yearSelect = calendar.querySelector("[data-calendar-year]")
    const daysGrid = calendar.querySelector("[data-calendar-days]")
    const display = calendar.querySelector("[data-calendar-display]")
    if (!valueInput || !openButton || !dialog || !monthSelect || !yearSelect || !daysGrid || !display) return

    calendar.dataset.calendarBound = "true"
    const initialDate = calendarDateFromIso(valueInput.value) || calendarToday()
    let viewedDate = new Date(Date.UTC(initialDate.getUTCFullYear(), initialDate.getUTCMonth(), 1))

    const renderCalendar = () => {
      const year = viewedDate.getUTCFullYear()
      const month = viewedDate.getUTCMonth()
      monthSelect.value = String(month)
      yearSelect.value = String(year)
      daysGrid.replaceChildren()

      const firstWeekday = new Date(Date.UTC(year, month, 1)).getUTCDay()
      const dayCount = new Date(Date.UTC(year, month + 1, 0)).getUTCDate()
      const selectedIso = valueInput.value
      const todayIso = calendarIsoDate(calendarToday())

      for (let blank = 0; blank < firstWeekday; blank += 1) {
        const spacer = document.createElement("span")
        spacer.className = "calendar-day-spacer"
        spacer.setAttribute("role", "gridcell")
        daysGrid.append(spacer)
      }

      for (let day = 1; day <= dayCount; day += 1) {
        const date = new Date(Date.UTC(year, month, day))
        const isoDate = calendarIsoDate(date)
        const button = document.createElement("button")
        button.type = "button"
        button.className = "calendar-day"
        button.textContent = String(day)
        button.setAttribute("role", "gridcell")
        button.setAttribute("aria-label", calendarDisplayDate(date))
        button.setAttribute("aria-selected", (isoDate === selectedIso).toString())
        if (isoDate === selectedIso) button.classList.add("calendar-day-selected")
        if (isoDate === todayIso) button.classList.add("calendar-day-today")
        button.addEventListener("click", () => {
          valueInput.value = isoDate
          display.textContent = calendarDisplayDate(date)
          valueInput.dispatchEvent(new Event("change", { bubbles: true }))
          dialog.close()
        })
        daysGrid.append(button)
      }
    }

    openButton.addEventListener("click", () => {
      const selected = calendarDateFromIso(valueInput.value)
      if (selected) viewedDate = new Date(Date.UTC(selected.getUTCFullYear(), selected.getUTCMonth(), 1))
      renderCalendar()
      dialog.showModal()
    })
    monthSelect.addEventListener("change", () => {
      viewedDate = new Date(Date.UTC(viewedDate.getUTCFullYear(), Number(monthSelect.value), 1))
      renderCalendar()
    })
    yearSelect.addEventListener("change", () => {
      viewedDate = new Date(Date.UTC(Number(yearSelect.value), viewedDate.getUTCMonth(), 1))
      renderCalendar()
    })
    calendar.querySelector("[data-calendar-previous]").addEventListener("click", () => {
      viewedDate = new Date(Date.UTC(viewedDate.getUTCFullYear(), viewedDate.getUTCMonth() - 1, 1))
      renderCalendar()
    })
    calendar.querySelector("[data-calendar-next]").addEventListener("click", () => {
      viewedDate = new Date(Date.UTC(viewedDate.getUTCFullYear(), viewedDate.getUTCMonth() + 1, 1))
      renderCalendar()
    })
    calendar.querySelector("[data-calendar-today]").addEventListener("click", () => {
      const utcToday = calendarToday()
      valueInput.value = calendarIsoDate(utcToday)
      display.textContent = calendarDisplayDate(utcToday)
      valueInput.dispatchEvent(new Event("change", { bubbles: true }))
      dialog.close()
    })
    calendar.querySelector("[data-calendar-clear]").addEventListener("click", () => {
      valueInput.value = ""
      display.textContent = "Choose a date"
      valueInput.dispatchEvent(new Event("change", { bubbles: true }))
      dialog.close()
    })
    calendar.querySelectorAll("[data-calendar-close]").forEach((button) => {
      button.addEventListener("click", () => dialog.close())
    })
  })
}

document.addEventListener("turbo:load", bindWeddingCalendars)

const bindSocialComposers = () => {
  document.querySelectorAll("[data-block-builder]").forEach((builder) => {
    if (builder.dataset.blockBuilderBound) return
    builder.dataset.blockBuilderBound = "true"
    const kind = builder.querySelector("[data-block-kind]")
    const updateFields = () => {
      builder.querySelectorAll("[data-block-fields]").forEach((field) => {
        field.hidden = !field.dataset.blockFields.split(" ").includes(kind.value)
        field.querySelectorAll("input, select, textarea").forEach((input) => { input.disabled = field.hidden })
      })
    }
    kind?.addEventListener("change", updateFields)
    updateFields()
  })

  document.querySelectorAll("[data-sticky-sheet]").forEach((form) => {
    if (form.dataset.stickySheetBound) return
    form.dataset.stickySheetBound = "true"
    const body = form.querySelector("[data-sheet-body]")
    const hidden = form.querySelector("[data-sheet-json]")
    form.querySelector("[data-sheet-add-row]")?.addEventListener("click", () => {
      if (body.rows.length >= 30) return
      const row = body.insertRow()
      const columns = body.rows[0]?.cells.length || 3
      for (let column = 0; column < columns; column += 1) {
        const cell = row.insertCell()
        const input = document.createElement("input")
        input.type = "text"
        input.maxLength = 500
        input.setAttribute("aria-label", "Spreadsheet cell")
        cell.append(input)
      }
    })
    form.querySelector("[data-sheet-add-column]")?.addEventListener("click", () => {
      if ((body.rows[0]?.cells.length || 0) >= 12) return
      Array.from(body.rows).forEach((row) => {
        const input = document.createElement("input")
        input.type = "text"
        input.maxLength = 500
        input.setAttribute("aria-label", "Spreadsheet cell")
        row.insertCell().append(input)
      })
    })
    form.addEventListener("submit", () => {
      hidden.value = JSON.stringify(Array.from(body.rows).map((row) => Array.from(row.querySelectorAll("input")).map((input) => input.value)))
    })
  })

  document.querySelectorAll("[data-sticky-list]").forEach((form) => {
    if (form.dataset.stickyListBound) return
    form.dataset.stickyListBound = "true"
    const container = form.querySelector("[data-list-items]")
    const hidden = form.querySelector("[data-list-json]")
    const newInput = form.querySelector("[data-list-new]")
    const addItem = () => {
      const text = newInput?.value.trim()
      if (!text || container.children.length >= 100) return
      const label = document.createElement("label")
      label.className = "sticky-list-item"
      label.dataset.listId = crypto.randomUUID()
      const checkbox = document.createElement("input")
      checkbox.type = "checkbox"
      const input = document.createElement("input")
      input.type = "text"
      input.maxLength = 500
      input.value = text
      input.setAttribute("aria-label", "List item")
      label.append(checkbox, input)
      container.append(label)
      newInput.value = ""
      newInput.focus()
    }
    form.querySelector("[data-list-add]")?.addEventListener("click", addItem)
    newInput?.addEventListener("keydown", (event) => {
      if (event.key === "Enter") { event.preventDefault(); addItem() }
    })
    form.addEventListener("submit", () => {
      hidden.value = JSON.stringify(Array.from(container.querySelectorAll("[data-list-id]")).map((item) => ({
        id: item.dataset.listId,
        done: item.querySelector('input[type="checkbox"]').checked,
        text: item.querySelector('input[type="text"]').value
      })))
    })
  })

  document.querySelectorAll(".create-panel").forEach((panel) => {
    const buttons = panel.querySelectorAll("[data-post-type-button]")
    const postPanel = panel.querySelector('[data-post-type-panel="post"]')
    const questionnairePanel = panel.querySelector('[data-post-type-panel="questionnaire"]')
    const postTypeInput = panel.querySelector("[data-post-type-value]")

    buttons.forEach((button) => {
      if (button.dataset.postTypeBound) return
      button.dataset.postTypeBound = "true"
      button.addEventListener("click", () => {
        const type = button.dataset.postTypeButton
        buttons.forEach((entry) => entry.classList.toggle("active", entry === button))
        if (postPanel) postPanel.hidden = type === "questionnaire"
        if (questionnairePanel) questionnairePanel.hidden = type !== "questionnaire"
        if (postTypeInput && type !== "questionnaire") postTypeInput.value = type
        const focusTarget = type === "questionnaire" ? questionnairePanel?.querySelector("input:not([type=hidden])") : postPanel?.querySelector(type === "media_post" ? 'input[type="file"]' : "textarea")
        focusTarget?.focus()
      })
    })
  })

  document.querySelectorAll("[data-insert-emoji]").forEach((button) => {
    if (button.dataset.emojiBound) return
    button.dataset.emojiBound = "true"
    button.addEventListener("click", () => {
      const composer = button.closest("form")
      const input = composer?.querySelector("[data-comment-text]")
      if (!input) return
      const start = input.selectionStart ?? input.value.length
      const end = input.selectionEnd ?? start
      input.setRangeText(button.dataset.insertEmoji, start, end, "end")
      input.focus()
      button.closest("details")?.removeAttribute("open")
    })
  })

  document.querySelectorAll("[data-comment-files]").forEach((input) => {
    if (input.dataset.filesBound) return
    input.dataset.filesBound = "true"
    input.addEventListener("change", () => {
      const preview = input.closest("form")?.querySelector("[data-comment-attachment-preview]")
      if (!preview) return
      preview.replaceChildren()
      Array.from(input.files).slice(0, 4).forEach((file) => {
        const item = document.createElement("span")
        item.textContent = `${file.type.startsWith("video/") ? "Video" : "Photo"}: ${file.name}`
        preview.append(item)
      })
      preview.hidden = input.files.length === 0
    })
  })

  document.querySelectorAll("textarea[data-comment-text]").forEach((textarea) => {
    if (textarea.dataset.autosizeBound) return
    textarea.dataset.autosizeBound = "true"
    const resize = () => {
      textarea.style.height = "auto"
      textarea.style.height = `${Math.min(textarea.scrollHeight, 180)}px`
    }
    textarea.addEventListener("input", resize)
    resize()
  })
}

document.addEventListener("turbo:load", bindSocialComposers)
document.addEventListener("turbo:before-stream-render", () => requestAnimationFrame(bindSocialComposers))
