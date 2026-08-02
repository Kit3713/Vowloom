class EventInvitation < ApplicationRecord
  belongs_to :event
  belongs_to :invitee

  enum :rsvp_status, { pending: 0, attending: 1, declined: 2 }, default: :pending

  validates :dietary_notes, :accessibility_notes, length: { maximum: 2_000 }
  validate :meal_choice_is_available

  private

  def meal_choice_is_available
    return if meal_choice.blank? || event&.meal_options&.include?(meal_choice)

    errors.add(:meal_choice, "must be one of the event meal options")
  end
end
