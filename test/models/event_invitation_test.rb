require "test_helper"

class EventInvitationTest < ActiveSupport::TestCase
  test "meal selections must match the configured event choices" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    event = site.events.create!(title: "Reception", meal_options: [ "Vegetarian", "Chicken" ])
    invitee = site.invitees.create!(first_name: "Taylor", last_name: "Tester")
    invitation = event.event_invitations.build(invitee: invitee, meal_choice: "Vegetarian")

    assert_predicate invitation, :valid?

    invitation.meal_choice = "Mystery meal"
    assert_not_predicate invitation, :valid?
    assert_includes invitation.errors[:meal_choice], "must be one of the event meal options"
  end

  test "RSVP deadlines cannot be after the event starts" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    event = site.events.build(title: "Reception", starts_at: 2.days.from_now, rsvp_deadline: 3.days.from_now)

    assert_not_predicate event, :valid?
    assert_includes event.errors[:rsvp_deadline], "must be on or before the event start time"
  end

  test "an event without a deadline keeps RSVPs open" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    event = site.events.create!(title: "Reception")

    assert_predicate event, :rsvp_open?
    assert_not_predicate event, :rsvp_closed?
  end
end
