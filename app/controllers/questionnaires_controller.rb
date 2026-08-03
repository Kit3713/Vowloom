class QuestionnairesController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_site

  def index
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @questionnaires = @site.questionnaires.where.not(status: :draft).order(created_at: :desc).select { |questionnaire| questionnaire.available_to?(Current.user) }
    @questionnaire = @site.questionnaires.build
    @available_groups = @site.groups.select { |group| group.accessible_to?(Current.user) }
    @available_events = @site.events.select { |event| event.visible_to?(Current.user) }
  end

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?

    @questionnaire = @site.questionnaires.find(params[:id])
    redirect_to questionnaires_path, alert: "That questionnaire is not available." and return unless (!@questionnaire.draft? && @questionnaire.available_to?(Current.user)) || @questionnaire.manageable_by?(Current.user)
    @response = response_for_current_user || @questionnaire.responses.build
    @response_editable = @questionnaire.response_editable?(@response)
    @staff_entry_invitees = @site.invitees.order(:last_name, :first_name) if staff?
    @result_summaries = build_result_summaries if @questionnaire.results_visible_to?(Current.user)
  end

  def create
    require_live_site!
    return redirect_to(questionnaires_path, alert: "Only staff can create questionnaires.") unless staff?
    template_key = params[:template]
    @questionnaire = @site.questionnaires.build(questionnaire_params.merge(created_by: Current.user))
    @questionnaire.title = QuestionnaireTemplates.title_for(template_key) if @questionnaire.title.blank? && QuestionnaireTemplates.keys.include?(template_key)
    @questionnaire.status = :published if params[:publish_now] == "1"
    return redirect_to(questionnaires_path, alert: "You cannot target that private group or event.") unless targets_accessible?(@questionnaire)

    if @questionnaire.save
      QuestionnaireTemplates.apply!(@questionnaire, template_key) if QuestionnaireTemplates.keys.include?(template_key)
      redirect_to @questionnaire, notice: "Questionnaire created. Add questions below."
    else
      @questionnaires = @site.questionnaires.published.order(created_at: :desc)
      @available_groups = @site.groups.select { |group| group.accessible_to?(Current.user) }
      @available_events = @site.events.select { |event| event.visible_to?(Current.user) }
      render :index, status: :unprocessable_content
    end
  end

  def update
    require_live_site!
    @questionnaire = @site.questionnaires.find(params[:id])
    return redirect_to(@questionnaire, alert: "You cannot edit that questionnaire.") unless @questionnaire.manageable_by?(Current.user)

    attributes = questionnaire_update_params
    if @questionnaire.structure_locked? && audience_changed?(attributes)
      return redirect_to(@questionnaire, alert: "Responses already exist, so the audience and response scope cannot be changed.")
    end

    @questionnaire.assign_attributes(attributes)
    return redirect_to(@questionnaire, alert: "You cannot target that private group or event.") unless targets_accessible?(@questionnaire)

    if @questionnaire.save
      redirect_to @questionnaire, notice: "Questionnaire settings saved."
    else
      @response = response_for_current_user || @questionnaire.responses.build
      @staff_entry_invitees = @site.invitees.order(:last_name, :first_name) if staff?
      @result_summaries = build_result_summaries if @questionnaire.results_visible_to?(Current.user)
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_site
    @site = current_site
    redirect_to new_setup_path and return unless @site
  end

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end

  def questionnaire_params
    params.require(:questionnaire).permit(:title, :introduction, :response_scope, :response_edit_policy, :results_visibility, :opens_at, :closes_at, :group_id, :event_id)
  end

  def questionnaire_update_params
    questionnaire_params.merge(params.require(:questionnaire).permit(:status))
  end

  def response_for_current_user
    return unless authenticated?
    @questionnaire.responses.find_by(user: Current.user)
  end

  def targets_accessible?(questionnaire)
    return true unless Current.user.helper?

    (questionnaire.group.blank? || questionnaire.group.accessible_to?(Current.user)) &&
      (questionnaire.event.blank? || questionnaire.event.visible_to?(Current.user))
  end

  def audience_changed?(attributes)
    %w[response_scope group_id event_id].any? do |attribute|
      attributes.key?(attribute) && @questionnaire.public_send(attribute).to_s != attributes[attribute].to_s
    end
  end

  def build_result_summaries
    responses = @questionnaire.responses.includes(:user, :invitee, :household, :answers)
    @questionnaire.questions.reject(&:information?).map do |question|
      answers = responses.filter_map do |response|
        answer = response.answers.find { |entry| entry.question_id == question.id }
        next unless answer

        { value: answer.value.fetch("answer", nil), respondent: respondent_name(response), file: answer.file.attached? }
      end
      {
        question:,
        response_count: answers.length,
        choices: choice_counts(question, answers),
        answers: @questionnaire.individual_results_visible_to?(Current.user) ? answers : []
      }
    end
  end

  def choice_counts(question, answers)
    return {} unless question.yes_no? || question.single_choice? || question.multiple_choice? || question.dropdown? || question.rating?

    answers.flat_map { |answer| Array(answer[:value]) }.compact.tally
  end

  def respondent_name(response)
    response.user&.display_name || response.invitee&.full_name || response.household&.name || "Unknown"
  end
end
