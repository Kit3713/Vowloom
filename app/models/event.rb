class Event < ApplicationRecord
  belongs_to :site
  has_many :event_invitations, dependent: :destroy
  has_many :invitees, through: :event_invitations
  has_many :groups, dependent: :nullify
  has_many :group_resources, as: :resourceable, dependent: :destroy

  enum :visibility, { site_wide: 0, invitees_only: 1 }, default: :site_wide

  validates :title, presence: true, length: { maximum: 140 }
  validate :ends_after_start
  validate :rsvp_deadline_before_event

  def visible_to?(user)
    site_wide? || user&.owner? || user&.admin? || user&.invitee_id.in?(invitee_ids)
  end

  def meal_options_text
    meal_options.join("\n")
  end

  def meal_options_text=(text)
    self.meal_options = text.to_s.lines.map(&:strip).reject(&:blank?)
  end

  def rsvp_open?
    rsvp_deadline.blank? || Time.current < rsvp_deadline
  end

  def rsvp_closed?
    !rsvp_open?
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank? || ends_at >= starts_at

    errors.add(:ends_at, "must be after the start time")
  end

  def rsvp_deadline_before_event
    return if rsvp_deadline.blank? || starts_at.blank? || rsvp_deadline <= starts_at

    errors.add(:rsvp_deadline, "must be on or before the event start time")
  end
end
