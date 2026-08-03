require "test_helper"

class RegistryItemTest < ActiveSupport::TestCase
  setup do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @collection = site.registry_collections.create!(title: "Home")
    @member = site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
  end

  test "claims are reserved atomically and released claims can be claimed again" do
    item = @collection.registry_items.create!(title: "Mixer", quantity_requested: 1)

    claim = item.claim!(@member)

    assert_predicate claim, :reserved?
    assert_equal 0, item.reload.available_quantity
    assert_raises(ActiveRecord::RecordInvalid) { item.claim!(@member) }

    claim.update!(status: :released)
    assert_equal 1, item.reload.available_quantity
  end

  test "item links must be safe web links and attached images must be images" do
    item = @collection.registry_items.build(title: "Mixer", external_url: "javascript:alert(1)")

    assert_not item.valid?
    assert_includes item.errors[:external_url], "must be a complete http or https link"

    item.external_url = "https://example.test/mixer"
    item.image.attach(io: File.open(file_fixture("photo.jpg")), filename: "photo.jpg", content_type: "image/jpeg")

    assert_predicate item, :valid?
    assert_predicate item.image, :attached?
  end

  test "purchaser identity remains hidden until received or explicitly revealed" do
    item = @collection.registry_items.create!(title: "Mixer")
    claim = item.claim!(@member)

    assert_not_predicate claim, :purchaser_visible?

    claim.update!(received_at: Time.current)
    assert_predicate claim, :purchaser_visible?
  end
end
