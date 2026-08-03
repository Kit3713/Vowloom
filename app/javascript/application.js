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
