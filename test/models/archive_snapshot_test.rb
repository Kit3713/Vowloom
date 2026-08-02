require "test_helper"

class ArchiveSnapshotTest < ActiveSupport::TestCase
  test "capture records immutable public-safe and complete exports without contacts or credentials" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    owner = site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    site.posts.create!(user: owner, space: :main, body: "Welcome", published_at: Time.current)
    site.posts.create!(user: owner, space: :couple_inbox, visibility: :members_only, body: "Private question", published_at: Time.current)
    site.groups.create!(created_by: owner, name: "Everyone", visibility: :site_wide)
    private_group = site.groups.create!(created_by: owner, name: "Private wedding party", visibility: :private_group)
    site.posts.create!(user: owner, group: private_group, space: :group_space, body: "Private group post", published_at: Time.current)
    site.events.create!(title: "Reception", visibility: :site_wide)
    site.events.create!(title: "Private rehearsal", visibility: :invitees_only)

    snapshot = ArchiveSnapshot.capture!(site: site, actor: owner)
    export = snapshot.export_payload

    site.posts.first.update!(body: "Changed after freeze")
    site.posts.create!(user: owner, space: :main, body: "Created after freeze", published_at: Time.current)

    assert_equal 3, snapshot.content_counts.fetch("posts")
    assert_equal 2, snapshot.manifest_version
    assert_equal "vowloom-portable-content-export", export.fetch(:format)
    assert_equal "Welcome", export.fetch(:posts).first.fetch(:body)
    assert_equal "Welcome", snapshot.export_payload.fetch(:posts).first.fetch(:body)
    assert_equal 1, snapshot.export_payload.fetch(:posts).size
    assert_not export.to_json.include?("password_digest")
    assert_not export.to_json.include?("Private question")
    assert_not_includes export.to_json, "Private group post"
    assert_includes export.to_json, "Reception"
    assert_not_includes export.to_json, "Private rehearsal"
    assert_includes export.to_json, "Everyone"
    assert_not_includes export.to_json, "Private wedding party"
    assert snapshot.export_payload(include_private: true).to_json.include?("Private question")
    assert snapshot.export_payload(include_private: true).to_json.include?("Private group post")
  end
end
