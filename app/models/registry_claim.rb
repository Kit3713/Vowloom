class RegistryClaim < ApplicationRecord
  belongs_to :registry_item
  belongs_to :user
  enum :status, { reserved: 0, purchased: 1, released: 2 }, default: :reserved
  validates :quantity, numericality: { greater_than: 0 }
  after_commit :broadcast_collection_totals, on: %i[create update]

  def purchaser_visible?
    received_at.present? || purchaser_revealed_at.present?
  end

  private

  def broadcast_collection_totals
    collection = registry_item.registry_collection
    Turbo::StreamsChannel.broadcast_update_to(
      collection,
      target: "registry_collection_#{collection.id}_totals",
      partial: "registry_collections/totals",
      locals: { collection: }
    )
  end
end
