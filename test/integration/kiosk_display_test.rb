require "test_helper"

class KioskDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Kiosk test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @display = @site.kiosk_displays.create!(name: "Reception wall", created_by: @owner, mode: :schedule, refresh_seconds: 45)
  end

  test "token kiosk shows only public schedule data and refreshes" do
    @site.events.create!(title: "Public reception", starts_at: 2.hours.from_now)
    @site.events.create!(title: "Private rehearsal", visibility: :invitees_only, starts_at: 1.hour.from_now)
    @site.posts.create!(user: @owner, space: :main, visibility: :everyone, body: "Public welcome", published_at: Time.current)
    @site.posts.create!(user: @owner, space: :main, visibility: :members_only, body: "Private note", published_at: Time.current)

    get public_display_path(@display.access_token)

    assert_response :success
    assert_select "main.kiosk-page.kiosk-schedule[data-refresh-seconds='45']"
    assert_select "meta[http-equiv='refresh'][content='45']"
    assert_select "strong", text: "Public reception"
    assert_select "strong", text: "Private rehearsal", count: 0
    assert_select "body", text: /Private note/, count: 0
  end

  test "owner updates a display preset and refresh interval" do
    sign_in(@owner)

    patch kiosk_display_path(@display), params: { kiosk_display: { mode: "slideshow", refresh_seconds: 90, show_qr_placeholder: "0", enabled: "1" } }

    assert_redirected_to kiosk_displays_path
    @display.reload
    assert_predicate @display, :slideshow?
    assert_equal 90, @display.refresh_seconds
    assert_not_predicate @display, :show_qr_placeholder?
  end

  private

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
