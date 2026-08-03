require "test_helper"

class RegistryCollectionTest < ActiveSupport::TestCase
  setup do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @collection = site.registry_collections.create!(title: "Giving")
    @member = site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
  end

  test "collection links only accept complete web links" do
    @collection.external_registry_url = "javascript:alert(1)"
    @collection.charity_url = "mailto:charity@example.test"
    @collection.cash_fund_url = "https://example.test/fund"

    assert_not_predicate @collection, :valid?
    assert_includes @collection.errors[:external_registry_url], "external registry link must be a complete http or https link"
    assert_includes @collection.errors[:charity_url], "charity link must be a complete http or https link"

    @collection.external_registry_url = "https://example.test/registry"
    @collection.charity_url = "http://example.test/charity"
    assert_predicate @collection, :valid?
  end

  test "visible totals include reserved and purchased gifts without purchaser data" do
    mixer = @collection.registry_items.create!(title: "Mixer", quantity_requested: 2)
    blender = @collection.registry_items.create!(title: "Blender", quantity_requested: 3)
    mixer.claim!(@member)
    blender.claim!(@member, quantity: 2).update!(status: :purchased)

    assert_equal 5, @collection.requested_quantity
    assert_equal 3, @collection.claimed_quantity
    assert_equal 2, @collection.remaining_quantity
  end
end
