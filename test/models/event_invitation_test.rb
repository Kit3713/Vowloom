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
end
