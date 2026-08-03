class QuestionsController < ApplicationController
  before_action :require_live_site!

  def create
    questionnaire = current_site.questionnaires.find(params[:questionnaire_id])
    return redirect_to(questionnaire, alert: "You cannot edit that questionnaire.") unless questionnaire.manageable_by?(Current.user)
    question = questionnaire.questions.build(question_params.merge(position: questionnaire.questions.maximum(:position).to_i + 1))
    if question.save
      redirect_to questionnaire, notice: "Question added."
    else
      redirect_to questionnaire, alert: question.errors.full_messages.to_sentence
    end
  end

  def update
    questionnaire = current_site.questionnaires.find(params[:questionnaire_id])
    return redirect_to(questionnaire, alert: "You cannot edit that questionnaire.") unless questionnaire.manageable_by?(Current.user)

    question = questionnaire.questions.find(params[:id])
    attributes = question_params
    attributes = attributes.slice(:prompt) if question.structure_locked?
    if question.update(attributes)
      notice = question.structure_locked? ? "Question wording updated. Existing answers keep their original structure." : "Question updated."
      redirect_to questionnaire, notice:
    else
      redirect_to questionnaire, alert: question.errors.full_messages.to_sentence
    end
  end

  def destroy
    questionnaire = current_site.questionnaires.find(params[:questionnaire_id])
    return redirect_to(questionnaire, alert: "You cannot edit that questionnaire.") unless questionnaire.manageable_by?(Current.user)

    question = questionnaire.questions.find(params[:id])
    return redirect_to(questionnaire, alert: "Questions with answers cannot be removed.") if question.structure_locked?

    question.destroy!
    redirect_to questionnaire, notice: "Question removed."
  end

  private

  def question_params
    permitted = params.require(:question).permit(:kind, :prompt, :required, :options_text, :conditional_question_id, :conditional_value)
    permitted[:options] = permitted.delete(:options_text).to_s.lines.map(&:strip).reject(&:blank?)
    conditional_question_id = permitted.delete(:conditional_question_id)
    conditional_value = permitted.delete(:conditional_value)
    permitted[:conditional_rule] = conditional_question_id.present? && conditional_value.present? ? { "question_id" => conditional_question_id, "equals" => conditional_value } : {}
    permitted
  end
end
