class Question < ApplicationRecord
  TYPES = %w[information short_text long_text yes_no single_choice multiple_choice dropdown number date time rating person file].freeze

  TYPES.each do |type|
    define_method("#{type}?") { kind == type }
  end

  belongs_to :questionnaire
  has_many :answers, class_name: "QuestionnaireAnswer", dependent: :restrict_with_exception

  validates :kind, inclusion: { in: TYPES }
  validates :prompt, presence: true, length: { maximum: 1_000 }
  validates :position, numericality: { greater_than: 0 }
  validate :conditional_question_is_earlier_question

  def options_text
    options.join("\n")
  end

  def conditional?
    conditional_rule["question_id"].present? && conditional_rule["equals"].present?
  end

  def visible_for?(answers)
    return true unless conditional?

    answer = answers[conditional_rule["question_id"].to_i]
    Array(answer).map(&:to_s).include?(conditional_rule["equals"].to_s)
  end

  def answer_allowed?(value)
    return true if value.blank? || information? || file?
    return value.in?(%w[yes no]) if yes_no?
    return Array(value).all? { |entry| options.include?(entry) } if multiple_choice?
    return options.include?(value) if single_choice? || dropdown?
    return questionnaire.site.invitees.exists?(id: value) if person?

    true
  end

  def structure_locked?
    answers.exists?
  end

  private

  def conditional_question_is_earlier_question
    return unless conditional?

    source = questionnaire&.questions&.find_by(id: conditional_rule["question_id"])
    return errors.add(:conditional_rule, "must refer to a question in this questionnaire") unless source
    return if source.position < position

    errors.add(:conditional_rule, "must refer to an earlier question")
  end
end
