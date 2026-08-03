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
    assert_equal 3, snapshot.manifest_version
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

  test "capture preserves structured operations while public export only has anonymous public history" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    owner = site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    guest = site.invitees.create!(first_name: "Casey", last_name: "Guest", email: "casey@example.test", phone: "555-0111")
    event = site.events.create!(title: "Ceremony", visibility: :site_wide, meal_options: [ "Vegetarian", "Chicken" ])
    event.event_invitations.create!(invitee: guest, rsvp_status: :attending, meal_choice: "Vegetarian", dietary_notes: "No dairy", accessibility_notes: "Aisle seat")
    private_event = site.events.create!(title: "Rehearsal", visibility: :invitees_only)

    public_questionnaire = site.questionnaires.create!(created_by: owner, title: "Song poll", status: :closed, results_visibility: :aggregate)
    public_question = public_questionnaire.questions.create!(prompt: "Choose a song", kind: "single_choice", options: [ "First", "Second" ], position: 1)
    public_response = public_questionnaire.responses.create!(user: owner, submitted_at: Time.current)
    public_response.answers.create!(question: public_question, value: { "answer" => "First" })
    private_questionnaire = site.questionnaires.create!(created_by: owner, title: "Private travel details", status: :closed, results_visibility: :staff_only)
    private_question = private_questionnaire.questions.create!(prompt: "Flight number", kind: "short_text", position: 1)
    private_response = private_questionnaire.responses.create!(invitee: guest, submitted_at: Time.current)
    private_response.answers.create!(question: private_question, value: { "answer" => "ZX42" })

    public_collection = site.registry_collections.create!(title: "Home", published: true, visibility: :everyone)
    public_item = public_collection.registry_items.create!(title: "Mixer", quantity_requested: 2, price_cents: 9_999)
    public_item.registry_claims.create!(user: owner, status: :purchased, quantity: 1, private_note: "Bought locally")
    private_collection = site.registry_collections.create!(title: "Private notes", published: false, visibility: :members_only)
    private_collection.registry_items.create!(title: "Hidden gift", quantity_requested: 1)

    group = site.groups.create!(created_by: owner, name: "Wedding party", visibility: :private_group)
    group.group_memberships.create!(user: owner)
    task = group.tasks.create!(title: "Bring flowers", description: "From the florist", assigned_user: owner, event: private_event, due_on: Date.current)
    task.task_comments.create!(user: owner, body: "Collected")

    snapshot = ArchiveSnapshot.capture!(site: site, actor: owner)
    public_export = snapshot.export_payload
    complete_export = snapshot.export_payload(include_private: true)

    # The event has exactly one RSVP: this asserts totals are present without
    # relying on any guest identity or sensitive details.
    assert_equal 1, public_export.dig(:events, 0, :rsvp_totals, :attending)
    assert_equal [ "Song poll" ], public_export.fetch(:questionnaires).map { |questionnaire| questionnaire.fetch(:title) }
    assert_equal({ First: 1 }, public_export.dig(:questionnaires, 0, :questions, 0, :aggregate, :choice_counts))
    assert_equal [ "Home" ], public_export.fetch(:registry).map { |collection| collection.fetch(:title) }
    assert_equal 1, public_export.dig(:registry, 0, :items, 0, :available_quantity)
    assert_empty public_export.fetch(:tasks)
    assert_not_includes public_export.to_json, "Casey Guest"
    assert_not_includes public_export.to_json, "No dairy"
    assert_not_includes public_export.to_json, "ZX42"
    assert_not_includes public_export.to_json, "Bought locally"
    assert_not_includes public_export.to_json, "Bring flowers"
    assert_not_includes public_export.to_json, "casey@example.test"
    assert_not_includes public_export.to_json, "555-0111"

    assert_equal 2, complete_export.fetch(:events).size
    assert_equal "Casey Guest", complete_export.dig(:events, 0, :rsvps, 0, :invitee)
    assert_equal "No dairy", complete_export.dig(:events, 0, :rsvps, 0, :dietary_notes)
    assert_equal 2, complete_export.fetch(:questionnaires).size
    assert_includes complete_export.to_json, "ZX42"
    assert_equal 2, complete_export.fetch(:registry).size
    assert_equal "Owner", complete_export.dig(:registry, 0, :items, 0, :claims, 0, :purchaser)
    assert_equal "Bought locally", complete_export.dig(:registry, 0, :items, 0, :claims, 0, :private_note)
    assert_equal "Bring flowers", complete_export.dig(:tasks, 0, :title)
    assert_includes complete_export.to_json, "Collected"
    assert_not_includes complete_export.to_json, "casey@example.test"
    assert_not_includes complete_export.to_json, "555-0111"
  end
end
