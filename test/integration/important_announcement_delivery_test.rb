require "test_helper"

class ImportantAnnouncementDeliveryTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @site = Site.create!(name: "Alex & Jordan", accent_color: "#8f4f6a")
    @owner = create_user("Owner", :owner)
    @member = create_invited_member("Alex", email: "alex@example.com", opted_in: true)
    @opted_out_member = create_invited_member("Casey", email: "casey@example.com", opted_in: false)
    @unlinked_member = create_user("Guest", :member, recovery_email: "guest@example.com", opted_in: true)
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
    sign_in(@owner)
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
  end

  test "owner can deliberately queue an opted-in invited member announcement" do
    get feed_path("main")
    assert_response :success
    assert_select "input[type='checkbox'][name='post[send_important_announcement_email]']"

    assert_difference [ "Post.count", "AnnouncementDelivery.count", "AuditEvent.count" ], 1 do
      assert_enqueued_jobs 1, only: ImportantAnnouncementDeliveryJob do
        post posts_path, params: {
          post: {
            space: "main",
            title: "Travel update",
            body: "The shuttle now leaves at 2 PM.",
            send_important_announcement_email: "1"
          }
        }
      end
    end

    post = @site.posts.last
    delivery = post.announcement_deliveries.sole
    assert_predicate post, :important_announcement?
    assert_not_nil post.announcement_email_queued_at
    assert_equal @member, delivery.recipient
    assert_predicate delivery, :pending?
    assert_equal "announcement.email_delivery_queued", @site.audit_events.last.action
    assert_equal 1, @site.audit_events.last.metadata.fetch("recipient_count")

    perform_enqueued_jobs only: ImportantAnnouncementDeliveryJob

    assert_predicate delivery.reload, :delivered?
    assert_equal [ @member.recovery_email ], ActionMailer::Base.deliveries.map(&:to).flatten
    assert_equal "Travel update", ActionMailer::Base.deliveries.sole.subject.split(": ").last
  end

  test "an opted-out member is not queued and a later opt-out cancels delivery" do
    post posts_path, params: {
      post: {
        space: "main",
        body: "Please read this event update.",
        send_important_announcement_email: "1"
      }
    }

    delivery = @site.posts.last.announcement_deliveries.sole
    @member.update!(important_announcement_emails: false)
    perform_enqueued_jobs only: ImportantAnnouncementDeliveryJob

    assert_predicate delivery.reload, :cancelled?
    assert_empty ActionMailer::Base.deliveries
    assert_empty @site.users.important_announcement_recipients
  end

  test "helper cannot force announcement email delivery" do
    delete session_path
    helper = create_user("Helper", :helper)
    sign_in(helper)

    assert_no_difference "AnnouncementDelivery.count" do
      assert_no_enqueued_jobs only: ImportantAnnouncementDeliveryJob do
        post posts_path, params: {
          post: {
            space: "main",
            body: "Routine update",
            send_important_announcement_email: "1"
          }
        }
      end
    end

    assert_redirected_to feed_path("main")
    assert_not_predicate @site.posts.last, :important_announcement?
  end

  test "profile keeps announcement email preference explicit" do
    delete session_path
    sign_in(@member)

    patch profile_path, params: {
      user: {
        display_name: @member.display_name,
        recovery_email: "updated@example.com",
        important_announcement_emails: "0"
      }
    }

    assert_redirected_to community_path
    @member.reload
    assert_equal "updated@example.com", @member.recovery_email
    assert_not_predicate @member, :important_announcement_emails?
  end

  test "members cannot opt in without a recovery email" do
    user = @site.users.build(
      display_name: "No email",
      login_identifier: "no-email-#{SecureRandom.hex(4)}",
      password: "password123",
      password_confirmation: "password123",
      important_announcement_emails: true
    )

    assert_not_predicate user, :valid?
    assert_includes user.errors[:recovery_email], "is required to receive important wedding announcements"
  end

  private

  def create_user(name, role, recovery_email: nil, opted_in: false)
    @site.users.create!(
      display_name: name,
      login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}",
      recovery_email:,
      important_announcement_emails: opted_in,
      password: "password123",
      password_confirmation: "password123",
      role:
    )
  end

  def create_invited_member(name, email:, opted_in:)
    household = @site.households.create!(name: "#{name} household")
    invitee = @site.invitees.create!(first_name: name, last_name: "Guest", household:)
    @site.users.create!(
      display_name: name,
      login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}",
      recovery_email: email,
      important_announcement_emails: opted_in,
      password: "password123",
      password_confirmation: "password123",
      role: :member,
      invitee:
    )
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
