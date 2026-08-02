require "csv"

class ReportsController < ApplicationController
  before_action :require_site_manager!

  def index
    @events = current_site.events.includes(event_invitations: :invitee).order(:starts_at)
    @questionnaires = current_site.questionnaires.includes(:responses).order(created_at: :desc)
    @collections = current_site.registry_collections.includes(registry_items: :registry_claims).order(:title)
  end

  def event_export
    event = current_site.events.find(params[:id])
    data = CSV.generate(headers: true) do |csv|
      csv << [ "Name", "Household", "RSVP", "Meal choice", "Dietary notes", "Accessibility notes", "Responded at" ]
      event.event_invitations.includes(invitee: :household).order("invitees.last_name", "invitees.first_name").each do |invitation|
        csv << [ invitation.invitee.full_name, invitation.invitee.household&.name, invitation.rsvp_status, invitation.meal_choice, invitation.dietary_notes, invitation.accessibility_notes, invitation.responded_at ]
      end
    end
    send_data data, filename: "#{event.title.parameterize.presence || 'event'}-rsvps.csv", type: "text/csv", disposition: "attachment"
  end

  def questionnaire_export
    questionnaire = current_site.questionnaires.includes(:questions, responses: [ :user, :invitee, :household, :answers ]).find(params[:id])
    data = CSV.generate(headers: true) do |csv|
      csv << [ "Respondent", "Submitted at", *questionnaire.questions.map(&:prompt) ]
      questionnaire.responses.each do |response|
        answers = response.answers.index_by(&:question_id)
        csv << [ respondent_name(response), response.submitted_at, *questionnaire.questions.map { |question| answers[question.id]&.value&.fetch("answer", nil) } ]
      end
    end
    send_data data, filename: "#{questionnaire.title.parameterize.presence || 'questionnaire'}-responses.csv", type: "text/csv", disposition: "attachment"
  end

  private

  def require_site_manager!
    return if Current.user.owner? || Current.user.admin?

    redirect_to community_path, alert: "Only owners and admins can access planning reports."
  end

  def respondent_name(response)
    response.user&.display_name || response.invitee&.full_name || response.household&.name || "Unknown"
  end
end
