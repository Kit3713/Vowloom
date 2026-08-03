class QuestionnaireTemplates
  TEMPLATES = {
    "travel" => {
      title: "Travel and lodging",
      questions: [
        { section: "Lodging", kind: "yes_no", prompt: "Will you need lodging information?", required: true },
        { section: "Lodging", kind: "short_text", prompt: "Where are you staying?", required: false },
        { section: "Travel", kind: "short_text", prompt: "When do you expect to arrive?", required: false }
      ]
    },
    "song_request" => {
      title: "Song requests",
      questions: [
        { kind: "short_text", prompt: "What song would get you on the dance floor?", required: false },
        { kind: "long_text", prompt: "Any note for the DJ?", required: false }
      ]
    },
    "accessibility" => {
      title: "Accessibility needs",
      questions: [
        { kind: "yes_no", prompt: "Do you have an accessibility need we should plan for?", required: true },
        { kind: "long_text", prompt: "Please tell us how we can make the day more comfortable.", required: false }
      ]
    },
    "meal_selection" => {
      title: "Meal selection",
      questions: [
        { section: "Your meal", kind: "single_choice", prompt: "Which meal would you prefer?", required: true, options: [ "Chicken", "Vegetarian", "Vegan", "Children’s meal" ] },
        { section: "Dietary needs", kind: "long_text", prompt: "Do you have allergies or dietary needs we should know about?", required: false }
      ]
    },
    "volunteer" => {
      title: "Volunteer availability",
      questions: [
        { kind: "multiple_choice", prompt: "Where could you help?", required: false, options: [ "Setup", "Guest welcome", "Transportation", "Cleanup" ] },
        { kind: "long_text", prompt: "When are you available?", required: false }
      ]
    },
    "rsvp_supplement" => {
      title: "RSVP details",
      questions: [
        { section: "Celebrating together", kind: "yes_no", prompt: "Will you need transportation information?", required: false },
        { section: "Celebrating together", kind: "long_text", prompt: "Is there anything that would help you enjoy the day?", required: false },
        { section: "Reception", kind: "short_text", prompt: "What song would get you on the dance floor?", required: false }
      ]
    },
    "contact_confirmation" => {
      title: "Contact confirmation",
      questions: [
        { section: "Stay in touch", kind: "short_text", prompt: "What is the best email address for wedding updates?", required: true },
        { section: "Stay in touch", kind: "short_text", prompt: "What is the best phone number for day-of updates?", required: false }
      ]
    },
    "informal_poll" => {
      title: "Quick poll",
      questions: [
        { kind: "single_choice", prompt: "Which option do you prefer?", required: true, options: [ "Option A", "Option B" ] },
        { kind: "long_text", prompt: "Anything else we should know?", required: false }
      ]
    }
  }.freeze

  def self.keys
    TEMPLATES.keys
  end

  def self.title_for(key)
    TEMPLATES.fetch(key).fetch(:title)
  end

  def self.apply!(questionnaire, key)
    template = TEMPLATES.fetch(key)
    template.fetch(:questions).each_with_index do |question, index|
      questionnaire.questions.create!(question.merge(position: index + 1, options: question.fetch(:options, [])))
    end
  end
end
