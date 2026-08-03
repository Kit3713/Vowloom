require "test_helper"

class SetupTest < ActionDispatch::IntegrationTest
  test "first-time initialization creates the owner and selected wedding starters" do
    get new_setup_path
    assert_response :success
    assert_select "h1", "Make Vowloom yours"
    assert_select ".setup-step", count: 4
    assert_select "dt", text: "Database"
    assert_select "[data-date-jump-control]", count: 1
    assert_select "input[data-date-jump-year]", count: 1
    assert_select ".email-delivery-status", text: /Email recovery is not active yet/
    assert_select "button.setup-submit[type='submit']", text: /Finish setup and open Vowloom/, count: 1
    assert_select "input.setup-submit", count: 0

    assert_difference [ "Site.count", "User.count", "Event.count", "Post.count", "Album.count", "AuditEvent.count" ], 1 do
      post setup_path, params: {
        site: {
          name: "Taylor and Jordan",
          wedding_date: "2028-06-10",
          accent_color: "#8f4f6a",
          access_policy: "private_access",
          time_zone: "Central Time (US & Canada)",
          media_quota_gigabytes: "35",
          landing_message: "Welcome"
        },
        owner: {
          display_name: "Taylor",
          login_identifier: "taylor",
          recovery_email: "taylor@example.com",
          password: "password123",
          password_confirmation: "password123"
        },
        event: {
          title: "Wedding ceremony",
          starts_at: "2028-06-10T15:00",
          ends_at: "2028-06-10T16:00",
          location_name: "Celebration Hall",
          visibility: "site_wide"
        },
        starter: { create_event: "1", create_welcome_post: "1", create_gallery_album: "1" }
      }
    end

    assert_redirected_to community_path
    site = Site.first
    assert_predicate site.users.first, :owner?
    assert_equal "Central Time (US & Canada)", site.time_zone
    assert_equal 35.gigabytes, site.media_quota_bytes
    assert_equal "Wedding ceremony", site.events.first.title
    assert_equal Time.find_zone!(site.time_zone).local(2028, 6, 10, 15), site.events.first.starts_at
    assert_predicate site.posts.first, :pinned?
    assert_equal "Wedding memories", site.albums.first.title
    assert_equal "site.initialized", site.audit_events.first.action
  end

  test "all application routes remain locked to setup before initialization" do
    get new_session_path
    assert_redirected_to new_setup_path

    get community_path
    assert_redirected_to new_setup_path

    get rails_health_check_path
    assert_response :success
  end

  test "an invalid selected starter rolls the entire initialization back" do
    assert_no_difference [ "Site.count", "User.count", "Event.count", "Post.count", "Album.count" ] do
      post setup_path, params: {
        site: {
          name: "Taylor and Jordan",
          accent_color: "#8f4f6a",
          access_policy: "private_access",
          time_zone: "Central Time (US & Canada)",
          media_quota_gigabytes: "20"
        },
        owner: {
          display_name: "Taylor",
          login_identifier: "taylor",
          password: "password123",
          password_confirmation: "password123"
        },
        event: {
          title: "Impossible event",
          starts_at: "2028-06-10T16:00",
          ends_at: "2028-06-10T15:00",
          visibility: "site_wide"
        },
        starter: { create_event: "1", create_welcome_post: "1", create_gallery_album: "1" }
      }
    end

    assert_response :unprocessable_content
    assert_select ".setup-errors", text: /Ends at must be after the start time/
    assert_select "h1", "Make Vowloom yours"
  end
end
