# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_03_034000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "album_exports", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "expires_at", null: false
    t.boolean "include_originals", default: false, null: false
    t.jsonb "media_asset_ids", default: [], null: false
    t.integer "media_count", default: 0, null: false
    t.bigint "requested_by_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["album_id", "status", "created_at"], name: "index_album_exports_on_album_id_and_status_and_created_at"
    t.index ["album_id"], name: "index_album_exports_on_album_id"
    t.index ["expires_at"], name: "index_album_exports_on_expires_at"
    t.index ["requested_by_id"], name: "index_album_exports_on_requested_by_id"
  end

  create_table "album_items", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.datetime "created_at", null: false
    t.bigint "media_asset_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["album_id", "media_asset_id"], name: "index_album_items_on_album_id_and_media_asset_id", unique: true
    t.index ["album_id"], name: "index_album_items_on_album_id"
    t.index ["media_asset_id"], name: "index_album_items_on_media_asset_id"
  end

  create_table "albums", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.bigint "event_id"
    t.boolean "featured", default: false, null: false
    t.bigint "site_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["created_by_id"], name: "index_albums_on_created_by_id"
    t.index ["event_id"], name: "index_albums_on_event_id"
    t.index ["site_id"], name: "index_albums_on_site_id"
  end

  create_table "announcement_deliveries", force: :cascade do |t|
    t.datetime "attempted_at"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.datetime "failed_at"
    t.string "failure_reason"
    t.bigint "post_id", null: false
    t.bigint "recipient_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "recipient_id"], name: "index_announcement_deliveries_on_post_id_and_recipient_id", unique: true
    t.index ["post_id"], name: "index_announcement_deliveries_on_post_id"
    t.index ["recipient_id"], name: "index_announcement_deliveries_on_recipient_id"
    t.index ["status", "created_at"], name: "index_announcement_deliveries_on_status_and_created_at"
  end

  create_table "archive_snapshots", force: :cascade do |t|
    t.string "checksum", null: false
    t.jsonb "content_counts", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "frozen_at", null: false
    t.integer "manifest_version", default: 1, null: false
    t.jsonb "private_payload", default: {}, null: false
    t.jsonb "public_payload", default: {}, null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_archive_snapshots_on_created_by_id"
    t.index ["site_id"], name: "index_archive_snapshots_on_site_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
    t.index ["site_id", "created_at"], name: "index_audit_events_on_site_id_and_created_at"
    t.index ["site_id"], name: "index_audit_events_on_site_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "hidden_at"
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "event_invitations", force: :cascade do |t|
    t.text "accessibility_notes"
    t.datetime "created_at", null: false
    t.text "dietary_notes"
    t.bigint "event_id", null: false
    t.bigint "invitee_id", null: false
    t.string "meal_choice"
    t.datetime "responded_at"
    t.integer "rsvp_status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "invitee_id"], name: "index_event_invitations_on_event_id_and_invitee_id", unique: true
    t.index ["event_id"], name: "index_event_invitations_on_event_id"
    t.index ["invitee_id"], name: "index_event_invitations_on_invitee_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.text "location_address"
    t.string "location_name"
    t.string "map_url"
    t.jsonb "meal_options", default: [], null: false
    t.datetime "rsvp_deadline"
    t.bigint "site_id", null: false
    t.datetime "starts_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["site_id"], name: "index_events_on_site_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "group_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "group_id", null: false
    t.integer "position", default: 0, null: false
    t.bigint "resourceable_id", null: false
    t.string "resourceable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_group_resources_on_created_by_id"
    t.index ["group_id", "position", "created_at"], name: "index_group_resources_on_group_id_and_position_and_created_at"
    t.index ["group_id", "resourceable_type", "resourceable_id"], name: "index_group_resources_on_group_and_resource", unique: true
    t.index ["group_id"], name: "index_group_resources_on_group_id"
    t.index ["resourceable_type", "resourceable_id"], name: "index_group_resources_on_resourceable"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.bigint "event_id"
    t.string "name", null: false
    t.integer "participation", default: 0, null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["created_by_id"], name: "index_groups_on_created_by_id"
    t.index ["event_id"], name: "index_groups_on_event_id"
    t.index ["site_id"], name: "index_groups_on_site_id"
  end

  create_table "households", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_households_on_site_id"
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.string "code_fingerprint"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "household_id"
    t.datetime "last_used_at"
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["code_digest"], name: "index_invitation_codes_on_code_digest", unique: true
    t.index ["code_fingerprint"], name: "index_invitation_codes_on_code_fingerprint", unique: true
    t.index ["household_id"], name: "index_invitation_codes_on_household_id"
    t.index ["site_id"], name: "index_invitation_codes_on_site_id"
  end

  create_table "invitees", force: :cascade do |t|
    t.integer "attendance_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name", null: false
    t.bigint "household_id"
    t.string "last_name", null: false
    t.string "phone"
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_invitees_on_household_id"
    t.index ["site_id"], name: "index_invitees_on_site_id"
  end

  create_table "kiosk_displays", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.boolean "enabled", default: true, null: false
    t.integer "mode", default: 0, null: false
    t.string "name", null: false
    t.bigint "questionnaire_id"
    t.integer "refresh_seconds", default: 60, null: false
    t.boolean "show_qr_placeholder", default: true, null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_kiosk_displays_on_access_token", unique: true
    t.index ["created_by_id"], name: "index_kiosk_displays_on_created_by_id"
    t.index ["questionnaire_id"], name: "index_kiosk_displays_on_questionnaire_id"
    t.index ["site_id"], name: "index_kiosk_displays_on_site_id"
  end

  create_table "media_assets", force: :cascade do |t|
    t.text "caption"
    t.datetime "created_at", null: false
    t.string "credit"
    t.bigint "event_id"
    t.boolean "featured", default: false, null: false
    t.bigint "post_id"
    t.bigint "site_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_media_assets_on_event_id"
    t.index ["post_id"], name: "index_media_assets_on_post_id"
    t.index ["site_id"], name: "index_media_assets_on_site_id"
    t.index ["user_id"], name: "index_media_assets_on_user_id"
  end

  create_table "moderation_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "handled_at"
    t.bigint "handled_by_id"
    t.text "reason"
    t.bigint "reportable_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reporter_id", null: false
    t.bigint "site_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["handled_by_id"], name: "index_moderation_reports_on_handled_by_id"
    t.index ["reportable_type", "reportable_id"], name: "index_moderation_reports_on_reportable"
    t.index ["reporter_id"], name: "index_moderation_reports_on_reporter_id"
    t.index ["site_id", "status", "created_at"], name: "index_moderation_reports_on_site_id_and_status_and_created_at"
    t.index ["site_id"], name: "index_moderation_reports_on_site_id"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "announcement_email_queued_at"
    t.text "body", null: false
    t.boolean "comments_enabled", default: true, null: false
    t.boolean "conversation", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "event_id"
    t.bigint "group_id"
    t.datetime "hidden_at"
    t.boolean "important_announcement", default: false, null: false
    t.boolean "pinned", default: false, null: false
    t.bigint "postable_id"
    t.string "postable_type"
    t.datetime "published_at"
    t.bigint "site_id", null: false
    t.integer "space", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["event_id"], name: "index_posts_on_event_id"
    t.index ["group_id"], name: "index_posts_on_group_conversation", unique: true, where: "((conversation = true) AND (group_id IS NOT NULL))"
    t.index ["group_id"], name: "index_posts_on_group_id"
    t.index ["postable_type", "postable_id"], name: "index_posts_on_postable_type_and_postable_id"
    t.index ["site_id", "space", "published_at"], name: "index_posts_on_site_id_and_space_and_published_at"
    t.index ["site_id"], name: "index_posts_on_global_conversation", unique: true, where: "((conversation = true) AND (group_id IS NULL))"
    t.index ["site_id"], name: "index_posts_on_site_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "questionnaire_answers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.bigint "questionnaire_response_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", default: {}, null: false
    t.index ["question_id"], name: "index_questionnaire_answers_on_question_id"
    t.index ["questionnaire_response_id", "question_id"], name: "index_questionnaire_answers_on_response_and_question", unique: true
    t.index ["questionnaire_response_id"], name: "index_questionnaire_answers_on_questionnaire_response_id"
  end

  create_table "questionnaire_audiences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "household_id"
    t.bigint "invitee_id"
    t.bigint "questionnaire_id", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_questionnaire_audiences_on_household_id"
    t.index ["invitee_id"], name: "index_questionnaire_audiences_on_invitee_id"
    t.index ["questionnaire_id", "household_id"], name: "index_questionnaire_audiences_on_questionnaire_and_household", unique: true, where: "(household_id IS NOT NULL)"
    t.index ["questionnaire_id", "invitee_id"], name: "index_questionnaire_audiences_on_questionnaire_and_invitee", unique: true, where: "(invitee_id IS NOT NULL)"
    t.index ["questionnaire_id"], name: "index_questionnaire_audiences_on_questionnaire_id"
    t.check_constraint "num_nonnulls(invitee_id, household_id) = 1", name: "questionnaire_audiences_one_target"
  end

  create_table "questionnaire_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "household_id"
    t.bigint "invitee_id"
    t.bigint "questionnaire_id", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["household_id"], name: "index_questionnaire_responses_on_household_id"
    t.index ["invitee_id"], name: "index_questionnaire_responses_on_invitee_id"
    t.index ["questionnaire_id"], name: "index_questionnaire_responses_on_questionnaire_id"
    t.index ["user_id"], name: "index_questionnaire_responses_on_user_id"
  end

  create_table "questionnaires", force: :cascade do |t|
    t.datetime "closes_at"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "event_id"
    t.bigint "group_id"
    t.text "introduction"
    t.datetime "opens_at"
    t.integer "response_edit_policy", default: 0, null: false
    t.integer "response_scope", default: 0, null: false
    t.integer "results_visibility", default: 0, null: false
    t.bigint "site_id", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_questionnaires_on_created_by_id"
    t.index ["event_id"], name: "index_questionnaires_on_event_id"
    t.index ["group_id"], name: "index_questionnaires_on_group_id"
    t.index ["site_id"], name: "index_questionnaires_on_site_id"
  end

  create_table "questions", force: :cascade do |t|
    t.jsonb "conditional_rule", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.jsonb "options", default: [], null: false
    t.integer "position", null: false
    t.text "prompt", null: false
    t.bigint "questionnaire_id", null: false
    t.boolean "required", default: false, null: false
    t.string "section"
    t.datetime "updated_at", null: false
    t.index ["questionnaire_id", "position"], name: "index_questions_on_questionnaire_id_and_position", unique: true
    t.index ["questionnaire_id", "section", "position"], name: "index_questions_on_questionnaire_section_and_position"
    t.index ["questionnaire_id"], name: "index_questions_on_questionnaire_id"
  end

  create_table "registry_claims", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "private_note"
    t.datetime "purchased_at"
    t.datetime "purchaser_revealed_at"
    t.integer "quantity", default: 1, null: false
    t.datetime "received_at"
    t.bigint "registry_item_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "thank_you_sent_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["registry_item_id", "user_id"], name: "index_registry_claims_on_registry_item_id_and_user_id", unique: true
    t.index ["registry_item_id"], name: "index_registry_claims_on_registry_item_id"
    t.index ["user_id"], name: "index_registry_claims_on_user_id"
  end

  create_table "registry_collections", force: :cascade do |t|
    t.string "cash_fund_url"
    t.string "charity_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "external_registry_url"
    t.boolean "published", default: false, null: false
    t.bigint "site_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["site_id"], name: "index_registry_collections_on_site_id"
  end

  create_table "registry_items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "description"
    t.string "external_url"
    t.integer "price_cents"
    t.integer "priority", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.integer "quantity_requested", default: 1, null: false
    t.bigint "registry_collection_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_registry_items_on_category"
    t.index ["registry_collection_id"], name: "index_registry_items_on_registry_collection_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "accent_color", default: "#8f4f6a", null: false
    t.integer "access_policy", default: 0, null: false
    t.integer "content_state", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "landing_message"
    t.bigint "media_quota_bytes", default: 21474836480, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.date "wedding_date"
  end

  create_table "task_comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["task_id"], name: "index_task_comments_on_task_id"
    t.index ["user_id"], name: "index_task_comments_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assigned_user_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_on"
    t.bigint "event_id"
    t.bigint "group_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_tasks_on_assigned_user_id"
    t.index ["event_id"], name: "index_tasks_on_event_id"
    t.index ["group_id"], name: "index_tasks_on_group_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", default: "", null: false
    t.boolean "important_announcement_emails", default: false, null: false
    t.bigint "invitee_id"
    t.string "login_identifier", null: false
    t.string "password_digest", null: false
    t.text "profile_summary"
    t.string "recovery_email"
    t.integer "role", default: 3, null: false
    t.bigint "site_id"
    t.datetime "updated_at", null: false
    t.index ["invitee_id"], name: "index_users_on_invitee_id", unique: true
    t.index ["login_identifier"], name: "index_users_on_login_identifier", unique: true
    t.index ["site_id"], name: "index_users_on_one_owner_per_site", unique: true, where: "(role = 0)"
    t.index ["site_id"], name: "index_users_on_site_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "album_exports", "albums"
  add_foreign_key "album_exports", "users", column: "requested_by_id"
  add_foreign_key "album_items", "albums"
  add_foreign_key "album_items", "media_assets"
  add_foreign_key "albums", "events"
  add_foreign_key "albums", "sites"
  add_foreign_key "albums", "users", column: "created_by_id"
  add_foreign_key "announcement_deliveries", "posts"
  add_foreign_key "announcement_deliveries", "users", column: "recipient_id"
  add_foreign_key "archive_snapshots", "sites"
  add_foreign_key "archive_snapshots", "users", column: "created_by_id"
  add_foreign_key "audit_events", "sites"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "event_invitations", "events"
  add_foreign_key "event_invitations", "invitees"
  add_foreign_key "events", "sites"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "group_resources", "groups"
  add_foreign_key "group_resources", "users", column: "created_by_id"
  add_foreign_key "groups", "events"
  add_foreign_key "groups", "sites"
  add_foreign_key "groups", "users", column: "created_by_id"
  add_foreign_key "households", "sites"
  add_foreign_key "invitation_codes", "households"
  add_foreign_key "invitation_codes", "sites"
  add_foreign_key "invitees", "households"
  add_foreign_key "invitees", "sites"
  add_foreign_key "kiosk_displays", "questionnaires"
  add_foreign_key "kiosk_displays", "sites"
  add_foreign_key "kiosk_displays", "users", column: "created_by_id"
  add_foreign_key "media_assets", "events"
  add_foreign_key "media_assets", "posts"
  add_foreign_key "media_assets", "sites"
  add_foreign_key "media_assets", "users"
  add_foreign_key "moderation_reports", "sites"
  add_foreign_key "moderation_reports", "users", column: "handled_by_id"
  add_foreign_key "moderation_reports", "users", column: "reporter_id"
  add_foreign_key "posts", "events"
  add_foreign_key "posts", "groups"
  add_foreign_key "posts", "sites"
  add_foreign_key "posts", "users"
  add_foreign_key "questionnaire_answers", "questionnaire_responses"
  add_foreign_key "questionnaire_answers", "questions"
  add_foreign_key "questionnaire_audiences", "households"
  add_foreign_key "questionnaire_audiences", "invitees"
  add_foreign_key "questionnaire_audiences", "questionnaires"
  add_foreign_key "questionnaire_responses", "households"
  add_foreign_key "questionnaire_responses", "invitees"
  add_foreign_key "questionnaire_responses", "questionnaires"
  add_foreign_key "questionnaire_responses", "users"
  add_foreign_key "questionnaires", "events"
  add_foreign_key "questionnaires", "groups"
  add_foreign_key "questionnaires", "sites"
  add_foreign_key "questionnaires", "users", column: "created_by_id"
  add_foreign_key "questions", "questionnaires"
  add_foreign_key "registry_claims", "registry_items"
  add_foreign_key "registry_claims", "users"
  add_foreign_key "registry_collections", "sites"
  add_foreign_key "registry_items", "registry_collections"
  add_foreign_key "sessions", "users"
  add_foreign_key "task_comments", "tasks"
  add_foreign_key "task_comments", "users"
  add_foreign_key "tasks", "events"
  add_foreign_key "tasks", "groups"
  add_foreign_key "tasks", "users", column: "assigned_user_id"
  add_foreign_key "users", "invitees"
  add_foreign_key "users", "sites"
end
