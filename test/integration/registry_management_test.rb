require "test_helper"

class RegistryManagementTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @collection = @site.registry_collections.create!(title: "Home", published: true)
    @item = @collection.registry_items.create!(title: "Mixer", quantity_requested: 2)
    @claim = @item.claim!(@member)
    post session_path, params: { login_identifier: @owner.login_identifier, password: "password123" }
  end

  test "staff can add item presentation details and a photo" do
    patch registry_item_path(@item), params: {
      registry_item: {
        title: "Stand mixer", category: "Kitchen", external_url: "https://example.test/mixer",
        price_cents: 24_999, priority: "most_wanted", image: fixture_file_upload("photo.jpg", "image/jpeg")
      }
    }

    assert_redirected_to registry_collections_path
    @item.reload
    assert_equal "Kitchen", @item.category
    assert_predicate @item, :priority_most_wanted?
    assert_predicate @item.image, :attached?
    assert AuditEvent.exists?(action: "registry_item_updated", auditable: @item)
  end

  test "gift tracking hides purchaser identity until staff deliberately reveal it" do
    get registry_collections_path

    assert_response :success
    assert_select ".management-row", text: /Purchaser hidden/

    patch registry_claim_path(@claim), params: { registry_claim: {}, reveal_purchaser: "1" }

    assert_redirected_to registry_collections_path
    assert_predicate @claim.reload, :purchaser_visible?
    assert AuditEvent.exists?(action: "registry_gift_tracking_updated", auditable: @claim)
  end

  test "staff can manage collection links and visitors see safe giving options with live totals" do
    patch registry_collection_path(@collection), params: {
      registry_collection: {
        title: "Giving", description: "Choose what feels right.", external_registry_url: "https://example.test/registry",
        charity_url: "https://example.test/charity", cash_fund_url: "https://example.test/fund"
      }
    }

    assert_redirected_to registry_collections_path
    @collection.reload
    assert_equal "https://example.test/registry", @collection.external_registry_url
    assert AuditEvent.exists?(action: "registry_collection_updated", auditable: @collection)

    get registry_collections_path
    assert_select "summary", text: "Manage this collection"
    assert_select "turbo-cable-stream-source", count: 1

    delete session_path
    get registry_collections_path

    assert_response :success
    assert_select "a[href='https://example.test/registry']", text: "Visit external registry"
    assert_select "a[href='https://example.test/charity']", text: "Give to charity"
    assert_select "a[href='https://example.test/fund']", text: "Contribute to cash fund"
    assert_select "#registry_collection_#{@collection.id}_totals", text: /1 of 2 gifts reserved/
    assert_select "#registry_collection_#{@collection.id}_totals", text: /Member/, count: 0
  end

  test "staff cannot save unsafe collection links" do
    patch registry_collection_path(@collection), params: {
      registry_collection: { external_registry_url: "javascript:alert(1)" }
    }

    assert_redirected_to registry_collections_path
    assert_nil @collection.reload.external_registry_url
    follow_redirect!
    assert_select ".flash", text: /complete http or https link/
  end

  test "frozen sites cannot update collection links" do
    @site.update!(content_state: :frozen)

    patch registry_collection_path(@collection), params: {
      registry_collection: { external_registry_url: "https://example.test/registry" }
    }

    assert_redirected_to community_path
    assert_nil @collection.reload.external_registry_url
  end
end
