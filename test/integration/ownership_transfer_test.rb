require "test_helper"

class OwnershipTransferTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = create_user("Taylor", :owner)
    @new_owner = create_user("Jordan", :member)
    @admin = create_user("Casey", :admin)
  end

  test "owner can deliberately transfer ownership and the action is audited" do
    sign_in(@owner)

    get management_path
    assert_select "form[action='#{transfer_management_ownership_path}']"
    assert_select "select[name='target_user_id'] option[value='#{@new_owner.id}']", text: /Jordan/
    assert_select "select[name='target_user_id'] option[value='#{@owner.id}']", count: 0

    post transfer_management_ownership_path, params: { target_user_id: @new_owner.id }

    assert_redirected_to community_path
    assert_predicate @owner.reload, :admin?
    assert_predicate @new_owner.reload, :owner?
    assert_equal 1, @site.users.where(role: :owner).count

    audit = @site.audit_events.order(:created_at).last
    assert_equal "site.ownership_transferred", audit.action
    assert_equal @owner, audit.actor
    assert_equal @new_owner, audit.auditable
    assert_equal @owner.id, audit.metadata.fetch("previous_owner_id")
    assert_equal @new_owner.id, audit.metadata.fetch("new_owner_id")

    get management_path
    assert_redirected_to community_path

    delete session_path
    sign_in(@new_owner)
    get management_path
    assert_response :success
  end

  test "only the current owner can transfer ownership" do
    sign_in(@admin)

    post transfer_management_ownership_path, params: { target_user_id: @new_owner.id }

    assert_redirected_to community_path
    assert_predicate @owner.reload, :owner?
    assert_predicate @new_owner.reload, :member?
    assert_equal 0, @site.audit_events.count
  end

  test "transfer cannot select a user from another site" do
    other_site = Site.create!(name: "Other wedding", accent_color: "#8f4f6a")
    other_user = other_site.users.create!(display_name: "Other", login_identifier: "other-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :member)
    sign_in(@owner)

    post transfer_management_ownership_path, params: { target_user_id: other_user.id }

    assert_redirected_to management_path
    assert_predicate @owner.reload, :owner?
    assert_predicate @new_owner.reload, :member?
    assert_equal 0, @site.audit_events.count
  end

  test "transfer cannot select the existing owner" do
    sign_in(@owner)

    post transfer_management_ownership_path, params: { target_user_id: @owner.id }

    assert_redirected_to management_path
    assert_predicate @owner.reload, :owner?
    assert_predicate @new_owner.reload, :member?
    assert_equal 0, @site.audit_events.count
  end

  private

  def create_user(name, role)
    @site.users.create!(display_name: name, login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role:)
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
