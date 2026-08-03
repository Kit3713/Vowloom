class Questionnaire < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"
  belongs_to :group, optional: true
  belongs_to :event, optional: true
  has_many :questions, -> { order(:position) }, dependent: :destroy
  has_many :responses, class_name: "QuestionnaireResponse", dependent: :destroy

  enum :status, { draft: 0, published: 1, closed: 2 }, default: :draft
  enum :response_scope, { individual: 0, household: 1 }, default: :individual
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

  def structure_locked?
    responses.exists?
  end

  private

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank? || closes_at >= opens_at

    errors.add(:closes_at, "must be after the opening time")
  end
end
