require "test_helper"

class GroupResourcesTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @related_event = @site.events.create!(title: "Rehearsal dinner", starts_at: 2.days.from_now)
    @event = @site.events.create!(title: "Wedding reception", starts_at: 3.days.from_now)
    @group = @site.groups.create!(name: "Wedding party", participation: :discussion, event: @related_event, created_by: @owner)
    @group.members << @member
    @questionnaire = @site.questionnaires.create!(title: "Wedding party travel plans", status: :published, group: @group, created_by: @owner)
    @album = @site.albums.create!(title: "Behind the scenes", created_by: @owner)
    @asset = @site.media_assets.build(user: @owner, status: :approved, caption: "Getting ready")
    @asset.file.attach(fixture_file_upload("photo.jpg", "image/jpeg"))
    @asset.save!
    sign_in(@owner)
  end

  test "group managers pin existing wedding resources while linked planning items appear automatically" do
    [ @event, @questionnaire, @album, @asset ].each do |resource|
      assert_difference "GroupResource.count", 1 do
        post group_group_resources_path(@group), params: { group_resource: { resource_key: "#{resource.class.name}:#{resource.id}" } }
      end
      assert_redirected_to group_path(@group)
    end

    get group_path(@group)

    assert_response :success
    assert_select "section[aria-label='Group planning resources']", text: /Planning resources/
    assert_select "a[href='#{event_path(@related_event)}']", text: "Open event"
    assert_select "a[href='#{event_path(@event)}']", text: "Open event"
    assert_select "a[href='#{questionnaire_path(@questionnaire)}']", text: "Open questionnaire", count: 1
    assert_select "a[href='#{gallery_path}#album_#{@album.id}']", text: "Open album"
    assert_select "a[href='#{download_media_asset_path(@asset)}']", text: "Download web copy"
    assert_select "button", text: "Unpin", count: 4
    assert_equal "group.resource_pinned", @site.audit_events.order(:created_at).last.action
  end

  test "only a group manager can pin or remove resources and another site's records cannot be pinned" do
    delete session_path
    sign_in(@member)

    assert_no_difference "GroupResource.count" do
      post group_group_resources_path(@group), params: { group_resource: { resource_key: "Event:#{@event.id}" } }
    end
    assert_redirected_to group_path(@group)
    assert_equal "Only this group's managers can pin resources.", flash[:alert]

    delete session_path
    sign_in(@owner)
    other_site = Site.create!(name: "Other wedding", accent_color: "#234567")
    outside_event = other_site.events.create!(title: "Other reception")

    assert_no_difference "GroupResource.count" do
      post group_group_resources_path(@group), params: { group_resource: { resource_key: "Event:#{outside_event.id}" } }
    end
    assert_redirected_to group_path(@group)
    assert_equal "Choose an event, questionnaire, album, or approved photo/video from this wedding site.", flash[:alert]
  end

  test "pinned media must already be approved" do
    submitted = @site.media_assets.build(user: @owner, caption: "Needs review")
    submitted.file.attach(fixture_file_upload("photo.jpg", "image/jpeg"))
    submitted.save!

    resource = @group.group_resources.build(resourceable: submitted, created_by: @owner)

    assert_not_predicate resource, :valid?
    assert_includes resource.errors[:resourceable], "must be approved before it can be pinned"
  end

  test "a helper group manager cannot discover or pin an invitee-only event" do
    private_event = @site.events.create!(title: "Private family lunch", visibility: :invitees_only)
    helper = @site.users.create!(display_name: "Helper", login_identifier: "helper-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :helper)
    helper_group = @site.groups.create!(name: "Helper tasks", created_by: helper)
    delete session_path
    sign_in(helper)

    get group_path(helper_group)
    assert_response :success
    assert_select "option", text: /#{Regexp.escape(private_event.title)}/, count: 0

    assert_no_difference "GroupResource.count" do
      post group_group_resources_path(helper_group), params: { group_resource: { resource_key: "Event:#{private_event.id}" } }
    end
    assert_redirected_to group_path(helper_group)
    assert_equal "Choose an event, questionnaire, album, or approved photo/video from this wedding site.", flash[:alert]
  end

  private

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
