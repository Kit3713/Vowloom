class ImportantAnnouncementDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery_id)
    delivery = AnnouncementDelivery.find_by(id: delivery_id)
    return unless delivery

    claimed = AnnouncementDelivery.pending.where(id: delivery.id).update_all(
      status: AnnouncementDelivery.statuses.fetch("sending"),
      attempted_at: Time.current,
      updated_at: Time.current
    )
    return unless claimed == 1

    delivery.reload
    unless delivery.post.email_announcement_deliverable? && delivery.recipient.important_announcement_email_eligible?
      delivery.update!(status: :cancelled)
      return
    end

    ImportantAnnouncementsMailer.announcement(delivery.post, delivery.recipient).deliver_now
    delivery.update!(status: :delivered, delivered_at: Time.current)
  rescue StandardError
    delivery&.update_columns(
      status: AnnouncementDelivery.statuses.fetch("failed"),
      failed_at: Time.current,
      failure_reason: "Delivery attempt failed",
      updated_at: Time.current
    ) if delivery&.sending?
    raise
  end
end
