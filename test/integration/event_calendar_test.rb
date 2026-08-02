require "test_helper"

class EventCalendarTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @event = @site.events.create!(title: "Reception", starts_at: Time.utc(2028, 6, 10, 18), ends_at: Time.utc(2028, 6, 10, 22), location_name: "Test Hall", description: "Dinner, dancing, and cake")
  end

  test "public event calendar download is valid calendar content" do
    get calendar_event_path(@event)

    assert_response :success
    assert_equal "text/calendar", response.media_type
    assert_includes response.body, "BEGIN:VCALENDAR"
    assert_includes response.body, "SUMMARY:Reception"
  end

  test "dedicated calendar page shows visible events in the requested month" do
    get calendar_path(month: "2028-06")

    assert_response :success
    assert_select "h1", text: "June 2028"
    assert_select "a.calendar-event", text: "Reception"
  end

  test "owner can view event management without a missing invitee column" do
    owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    post session_path, params: { login_identifier: owner.login_identifier, password: "password123" }

    get event_path(@event)

    assert_response :success
  end

  test "owner can invite a roster member to an event" do
    owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    invitee = @site.invitees.create!(first_name: "Alex", last_name: "Guest")
    @event.update!(meal_options: [ "Vegetarian", "Chicken" ])
    post session_path, params: { login_identifier: owner.login_identifier, password: "password123" }

    assert_difference "EventInvitation.count", 1 do
      post event_event_invitations_path(@event), params: { invitee_id: invitee.id }
    end

    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_select ".flash", text: "Alex Guest has been invited."

    invitation = @event.event_invitations.find_by!(invitee:)
    patch event_event_invitation_path(@event, invitation), params: { event_invitation: { rsvp_status: "attending", meal_choice: "Vegetarian", dietary_notes: "No dairy", accessibility_notes: "Step-free entrance" } }

    invitation.reload
    assert_predicate invitation, :attending?
    assert_equal "Vegetarian", invitation.meal_choice
    assert_equal "No dairy", invitation.dietary_notes
  end

  test "an invited member can submit an RSVP for another person in their household" do
    household = @site.households.create!(name: "Guest household")
    primary = @site.invitees.create!(first_name: "Jamie", last_name: "Guest", household:)
    partner = @site.invitees.create!(first_name: "Alex", last_name: "Guest", household:)
    member = @site.users.create!(display_name: "Jamie", login_identifier: "jamie-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", invitee: primary)
    @event.event_invitations.create!(invitee: primary)
    partner_invitation = @event.event_invitations.create!(invitee: partner)
    post session_path, params: { login_identifier: member.login_identifier, password: "password123" }

    patch event_rsvp_path(@event), params: { rsvp: { invitee_id: partner.id, rsvp_status: "attending" } }

    assert_predicate partner_invitation.reload, :attending?
  end
end
