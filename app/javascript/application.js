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
