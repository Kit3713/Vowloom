require "test_helper"

class AccessPolicyTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = create_user("Owner", :owner)
  end

  test "public sites show the cover and allow visitor browsing" do
    get root_path
    assert_response :success
    assert_select "html[lang='en']"
    assert_select "a.skip-link[href='#page-content']", text: "Skip to page content"
    assert_select "a", text: "Continue as visitor"

    get community_path
    assert_response :success
  end

  test "invalid sign-in feedback is announced once" do
    post session_path, params: { login_identifier: "unknown", password: "not-the-password" }

    follow_redirect!

    assert_select ".flash-alert[role='alert']", text: "Try another sign-in name or password.", count: 1
    assert_select ".flash-notice", count: 0
  end

  test "private sites retain the cover but gate the community" do
    @site.update!(access_policy: :private_access)

    get root_path
    assert_response :success
    assert_select "a", text: "Sign in"
    assert_select "a", text: "Continue as visitor", count: 0

    get community_path
    assert_redirected_to new_session_path
  end

  test "only the owner may reach management" do
    sign_in(@owner)
    get management_path
    assert_response :success

    delete session_path
    member = create_user("Member", :member)
    sign_in(member)
    get management_path
    assert_redirected_to community_path
  end

  test "owner setting changes are recorded in the audit log" do
    sign_in(@owner)

    patch management_path, params: { site: { name: "Updated Vowloom", accent_color: "#8f4f6a", access_policy: "public_access", content_state: "live" } }

    assert_redirected_to management_path
    assert_equal "site.updated", @site.audit_events.order(:created_at).last.action
    assert_equal @owner, @site.audit_events.order(:created_at).last.actor
  end

  test "an invited signed-in member retains access to an invite-only event" do
    household = @site.households.create!(name: "Guest household")
    invitee = @site.invitees.create!(first_name: "Alex", last_name: "Guest", household:)
    member = @site.users.create!(display_name: "Alex", login_identifier: "alex-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", invitee:)
    event = @site.events.create!(title: "Rehearsal", visibility: :invitees_only)
    event.event_invitations.create!(invitee:)
    sign_in(member)

    get event_path(event)

    assert_response :success
    assert_select "h1", text: "Rehearsal"
  end

  test "community puts a signed-in member's outstanding RSVP and questionnaires first" do
    household = @site.households.create!(name: "Guest household")
    invitee = @site.invitees.create!(first_name: "Alex", last_name: "Guest", household:)
    member = @site.users.create!(display_name: "Alex", login_identifier: "alex-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", invitee:)
    event = @site.events.create!(title: "Reception", starts_at: 2.days.from_now)
    event.event_invitations.create!(invitee:)
    questionnaire = @site.questionnaires.create!(title: "Meal preference", created_by: @owner, status: :published)
    questionnaire.questions.create!(position: 1, kind: :single_choice, prompt: "Choose", options: [ "Vegetarian", "Chicken" ])
    sign_in(member)

    get community_path

    assert_response :success
    assert_select "section[aria-label='Your wedding to-dos']", text: /RSVP for Reception/
    assert_select "section[aria-label='Your wedding to-dos']", text: /Meal preference/
  end

  test "private sites do not expose a site-wide event or group by direct link" do
    @site.update!(access_policy: :private_access)
    event = @site.events.create!(title: "Reception")
    group = @site.groups.create!(name: "Family", created_by: @owner)

    get event_path(event)
    assert_redirected_to new_session_path

    get group_path(group)
    assert_redirected_to new_session_path
  end

  private

  def create_user(name, role)
    @site.users.create!(display_name: name, login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: role)
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
