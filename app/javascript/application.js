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

const daysInMonth = (year, month) => new Date(Date.UTC(year, month, 0)).getUTCDate()

const bindDateJumpControls = () => {
  document.querySelectorAll("[data-date-jump-control]").forEach((control) => {
    if (control.dataset.dateJumpBound) return

    const dateInput = control.querySelector("[data-date-jump-date]")
    const yearInput = control.querySelector("[data-date-jump-year]")
    if (!dateInput || !yearInput) return

    control.dataset.dateJumpBound = "true"
    yearInput.addEventListener("change", () => {
      const year = Number.parseInt(yearInput.value, 10)
      if (!Number.isInteger(year) || year < 1900 || year > 2200) return

      const current = dateInput.value ? dateInput.value.split("-").map(Number) : [year, new Date().getMonth() + 1, new Date().getDate()]
      const month = current[1]
      const day = Math.min(current[2], daysInMonth(year, month))
      dateInput.value = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`
      dateInput.dispatchEvent(new Event("change", { bubbles: true }))
    })

    dateInput.addEventListener("change", () => {
      if (dateInput.value) yearInput.value = dateInput.value.slice(0, 4)
    })
  })
}

document.addEventListener("turbo:load", bindDateJumpControls)
