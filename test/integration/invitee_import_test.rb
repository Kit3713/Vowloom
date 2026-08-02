require "test_helper"

class InviteeImportTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @admin = @site.users.create!(display_name: "Admin", login_identifier: "admin-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :admin)
    post session_path, params: { login_identifier: @admin.login_identifier, password: "password123" }
  end

  test "admin imports a household guest roster from CSV" do
    file = fixture_file_upload("guests.csv", "text/csv")

    post import_invitees_path, params: { file: file }

    assert_redirected_to management_path
    assert_equal 1, @site.households.where(name: "Test Household").count
    assert_equal 2, @site.invitees.where(last_name: "Guest").count
    assert @site.invitees.find_by(first_name: "Alex").user.nil?
  end
end
