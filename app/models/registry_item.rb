class RegistryItem < ApplicationRecord
  belongs_to :registry_collection
  has_many :registry_claims, dependent: :destroy
  has_one_attached :image
  enum :priority, { nice_to_have: 0, wanted: 1, most_wanted: 2 }, prefix: true

  after_commit :broadcast_collection_totals, on: %i[create update]

  validates :title, presence: true, length: { maximum: 180 }
  validates :category, length: { maximum: 80 }, allow_blank: true
  validates :quantity_requested, numericality: { greater_than: 0 }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :priority, inclusion: { in: priorities.keys }
  validate :external_url_is_http
  validate :image_is_an_image
  validate :quantity_covers_active_claims

  def available_quantity
    quantity_requested - registry_claims.where(status: %i[reserved purchased]).sum(:quantity)
  end

  def claim!(user, quantity: 1)
    with_lock do
      raise ActiveRecord::RecordInvalid.new(self), "Not enough remaining" if quantity > available_quantity

      claim = registry_claims.find_or_initialize_by(user:)
      claim.quantity = claim.persisted? && (claim.reserved? || claim.purchased?) ? claim.quantity + quantity : quantity
      claim.status = :reserved
      claim.save!
      claim
    end
  end

  private

  def external_url_is_http
    return if external_url.blank?

    uri = URI.parse(external_url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:external_url, "must be a complete http or https link")
  rescue URI::InvalidURIError
    errors.add(:external_url, "must be a complete http or https link")
  end

  def image_is_an_image
    return unless image.attached?
    return if image.content_type.in?(%w[image/png image/jpeg image/webp image/gif]) && image.byte_size <= 10.megabytes

    errors.add(:image, "must be an image no larger than 10 MB")
  end

  def quantity_covers_active_claims
    return if quantity_requested.blank? || !persisted?

    active_quantity = registry_claims.where(status: %i[reserved purchased]).sum(:quantity)
    return if quantity_requested >= active_quantity

    errors.add(:quantity_requested, "cannot be lower than the #{active_quantity} gifts already reserved")
  end

  def broadcast_collection_totals
    collection = registry_collection
    Turbo::StreamsChannel.broadcast_update_to(
      collection,
      target: "registry_collection_#{collection.id}_totals",
      partial: "registry_collections/totals",
      locals: { collection: }
    )
  end
end
