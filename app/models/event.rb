class Event < ApplicationRecord
  belongs_to :site
  has_many :event_invitations, dependent: :destroy
  has_many :invitees, through: :event_invitations

  enum :visibility, { site_wide: 0, invitees_only: 1 }, default: :site_wide

  validates :title, presence: true, length: { maximum: 140 }
  validate :ends_after_start

  def visible_to?(user)
    site_wide? || user&.owner? || user&.admin? || user&.invitee_id.in?(invitee_ids)
  end

  def meal_options_text
    meal_options.join("\n")
  end

  def meal_options_text=(text)
    self.meal_options = text.to_s.lines.map(&:strip).reject(&:blank?)
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank? || ends_at >= starts_at

    errors.add(:ends_at, "must be after the start time")
  end
end
