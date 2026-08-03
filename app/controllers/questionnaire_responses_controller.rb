class QuestionnaireResponsesController < ApplicationController
  before_action :require_live_site!

  def create
    questionnaire = current_site.questionnaires.find(params[:questionnaire_id])
    return redirect_to(questionnaire, alert: "This questionnaire is not available to you.") unless questionnaire.available_to?(Current.user) || questionnaire.manageable_by?(Current.user)
    return redirect_to(questionnaire, alert: "This questionnaire is closed.") unless questionnaire.open_for_responses?

    response = response_for(questionnaire)
    return redirect_to(questionnaire, alert: "Choose an invited person included in this questionnaire's audience.") unless response
    return redirect_to(questionnaire, alert: "This questionnaire accepts one submission per respondent.") unless questionnaire.response_editable?(response)

    response.save!

    submitted_answers = answer_values(response)
    questionnaire.questions.each do |question|
      next if question.information?

      answer = response.answers.find_or_initialize_by(question:)
      unless question.visible_for?(submitted_answers)
        answer.destroy! if answer.persisted?
        next
      end

      value = submitted_answers[question.id]
      file = params.fetch(:files, {}).fetch(question.id.to_s, nil)
      if value.blank? && file.blank? && !question.required?
        answer.destroy! if answer.persisted? && !question.file?
        next
      end
      required_value_missing = value.blank? && file.blank? && !answer.file.attached?
      return redirect_to(questionnaire, alert: "#{question.prompt} is required.") if question.required? && required_value_missing
      return redirect_to(questionnaire, alert: "#{question.prompt} has an invalid answer.") unless question.answer_allowed?(value)

      answer.value = { "answer" => value } unless question.file?
      answer.file.attach(file) if file.present?
      answer.save!
    end
    response.update!(submitted_at: Time.current)
    redirect_to questionnaire, notice: "Your answers have been saved."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to questionnaire, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def response_for(questionnaire)
    return staff_response_for(questionnaire) if staff? && params[:staff_invitee_id].present?
    return questionnaire.responses.find_or_initialize_by(user: Current.user) unless questionnaire.household?

    household = Current.user.invitee&.household
    questionnaire.responses.find_or_initialize_by(household:) if household
  end

  def staff_response_for(questionnaire)
    invitee = current_site.invitees.find(params[:staff_invitee_id])
    return unless questionnaire.audience_includes_invitee?(invitee)
    return questionnaire.responses.find_or_initialize_by(invitee:) unless questionnaire.household?

    questionnaire.responses.find_or_initialize_by(household: invitee.household) if invitee.household
  end

  def answer_values(response)
    existing_answers = response.answers.index_by(&:question_id).transform_values { |answer| answer.value.fetch("answer", nil) }
    submitted = params.fetch(:answers, {}).respond_to?(:to_unsafe_h) ? params.fetch(:answers).to_unsafe_h : params.fetch(:answers, {})
    submitted.each_with_object(existing_answers) do |(question_id, value), answers|
      answers[question_id.to_i] = value
    end
  end

  def staff?
    Current.user.owner? || Current.user.admin? || Current.user.helper?
  end
end
