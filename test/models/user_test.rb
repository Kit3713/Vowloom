require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
  end

  test "a site cannot have more than one owner at the model or database level" do
    second_owner = @site.users.build(display_name: "Second owner", login_identifier: "second-owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)

    assert_not second_owner.valid?
    assert_includes second_owner.errors[:role], "is already assigned to another user for this site"
    assert_raises ActiveRecord::RecordNotUnique do
      second_owner.save!(validate: false)
    end
  end

  test "passwords require eight characters" do
    user = @site.users.build(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "1234567", password_confirmation: "1234567")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"

    user.password = user.password_confirmation = "12345678"
    assert_predicate user, :valid?
  end
end
