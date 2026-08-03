class Questionnaire < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"
  belongs_to :group, optional: true
  belongs_to :event, optional: true
  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :responses, class_name: "QuestionnaireResponse", dependent: :destroy

  enum :status, { draft: 0, published: 1, closed: 2 }, default: :draft
  enum :response_scope, { individual: 0, household: 1 }, default: :individual
  enum :response_edit_policy, { editable_until_close: 0, locked_after_submission: 1 }, default: :editable_until_close
  enum :results_visibility, { staff_only: 0, respondent_and_staff: 1, aggregate: 2, member_visible: 3 }, default: :staff_only

  validates :title, presence: true, length: { maximum: 180 }
  validate :closes_after_opens

  def open_for_responses?
    published? && (opens_at.blank? || opens_at <= Time.current) && (closes_at.blank? || closes_at >= Time.current)
  end

  def available_to?(user)
    return false unless user
    return false if group && !group.accessible_to?(user)
    return false if event && !event.visible_to?(user)

    true
  end

  def manageable_by?(user)
    return true if user&.owner? || user&.admin?
    return false unless user&.helper?

    created_by == user || available_to?(user)
  end

  def results_visible_to?(user)
    return true if user&.owner? || user&.admin? || user&.helper?

    user.present? && (aggregate? || member_visible?)
  end

  def individual_results_visible_to?(user)
    return true if user&.owner? || user&.admin? || user&.helper?

    user.present? && member_visible?
  end

  def kiosk_displayable?
    published? && aggregate? && (group.blank? || group.site_wide?) && (event.blank? || event.site_wide?)
  end

  def structure_locked?
    responses.exists?
  end

  def response_editable?(response)
    return true unless response&.submitted_at?

    editable_until_close?
  end

  def response_visible_to?(response, user)
    return false unless response && user
    return true if staff_member?(user)

    response.user_id == user.id || (response.household_id.present? && response.household_id == user.invitee&.household_id)
  end

  def response_edit_policy_summary
    editable_until_close? ? "Responses can be updated until this questionnaire closes." : "Each respondent can submit once; staff can still view submitted answers."
  end

  def results_policy_summary
    case results_visibility
    when "staff_only"
      "Only wedding staff can view submitted results."
    when "respondent_and_staff"
      "Each respondent can review their own answers; only wedding staff can view everyone’s answers."
    when "aggregate"
      "Members can view anonymous totals, while only wedding staff can view individual answers."
    else
      "Members can view submitted responses and respondent names."
    end
  end

  private

  def staff_member?(user)
    user.owner? || user.admin? || user.helper?
  end

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank? || closes_at >= opens_at

    errors.add(:closes_at, "must be after the opening time")
  end
end
