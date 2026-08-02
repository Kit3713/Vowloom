require "test_helper"

class SetupTest < ActionDispatch::IntegrationTest
  test "first-time setup creates the site and its single owner" do
    get new_setup_path
    assert_response :success

    assert_difference [ "Site.count", "User.count" ], 1 do
      post setup_path, params: {
        site: { name: "Taylor and Jordan", wedding_date: "2028-06-10", accent_color: "#8f4f6a", access_policy: "private_access", landing_message: "Welcome" },
        owner: { display_name: "Taylor", login_identifier: "taylor", password: "password123", password_confirmation: "password123" }
      }
    end

    assert_redirected_to community_path
    assert_predicate Site.first.users.first, :owner?
  end
end
