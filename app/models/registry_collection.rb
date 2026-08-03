class RegistryCollection < ApplicationRecord
  belongs_to :site
  has_many :registry_items, dependent: :destroy
  enum :visibility, { everyone: 0, members_only: 1 }, default: :everyone
  validates :title, presence: true, length: { maximum: 180 }

  validate :external_links_are_http

  def requested_quantity
    registry_items.where(published: true).sum(:quantity_requested)
  end

  def claimed_quantity
    RegistryClaim.joins(:registry_item)
      .where(registry_items: { registry_collection_id: id, published: true })
      .where(status: %i[reserved purchased])
      .sum(:quantity)
  end

  def remaining_quantity
    requested_quantity - claimed_quantity
  end

  private

  def external_links_are_http
    {
      external_registry_url: "External registry link",
      charity_url: "Charity link",
      cash_fund_url: "Cash fund link"
    }.each do |attribute, label|
      value = public_send(attribute)
      next if value.blank?

      uri = URI.parse(value)
      next if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(attribute, "#{label.downcase} must be a complete http or https link")
    rescue URI::InvalidURIError
      errors.add(attribute, "#{label.downcase} must be a complete http or https link")
    end
  end
end
