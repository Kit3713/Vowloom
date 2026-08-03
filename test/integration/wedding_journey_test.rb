require "test_helper"

class WeddingJourneyTest < ActionDispatch::IntegrationTest
  test "an invited relative can create an account, RSVP, comment, and share a photo" do
    site = Site.create!(name: "Sam and Riley", access_policy: :public_access, accent_color: "#8f4f6a")
    owner = site.users.create!(display_name: "Sam", login_identifier: "sam-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    household = site.households.create!(name: "Taylor household")
    invitee = site.invitees.create!(first_name: "Taylor", last_name: "Guest", household:)
    code = InvitationCode.issue_for!(site:, household:)
    event = site.events.create!(title: "Reception", starts_at: 2.months.from_now, meal_options: [ "Vegetarian", "Chicken" ])
    invitation = event.event_invitations.create!(invitee:)
    announcement = site.posts.create!(user: owner, space: :main, visibility: :everyone, title: "Welcome", body: "We cannot wait to celebrate.", published_at: Time.current)

    get root_path
    assert_response :success
    assert_select "a", text: "Continue as visitor"

    get new_registration_path(invitation_code: code)
    assert_response :success
    assert_select "option", text: "Taylor Guest"

    assert_difference "site.users.count", 1 do
      post registration_path, params: {
        invitation_code: code,
        invitee_id: invitee.id,
        user: {
          display_name: "Taylor",
          login_identifier: "taylor-#{SecureRandom.hex(4)}",
          password: "a-longer-password",
          password_confirmation: "a-longer-password"
        }
      }
    end
    assert_redirected_to community_path

    patch event_rsvp_path(event), params: { rsvp: { rsvp_status: "attending", meal_choice: "Vegetarian" } }
    assert_redirected_to event_path(event)
    assert_equal "attending", invitation.reload.rsvp_status
    assert_equal "Vegetarian", invitation.meal_choice

    assert_difference "announcement.comments.count", 1 do
      post post_comments_path(announcement), params: { comment: { body: "Looking forward to it!" } }
    end
    assert_redirected_to feed_path("main")

    assert_difference "site.media_assets.count", 1 do
      post media_assets_path, params: { media_asset: { caption: "A family photo", file: fixture_file_upload("photo.jpg", "image/jpeg") } }
    end
    assert_redirected_to gallery_path
    assert_equal "submitted", site.media_assets.order(:created_at).last.status
  end
end
