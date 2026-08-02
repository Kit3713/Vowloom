class RegistryItem < ApplicationRecord
  belongs_to :registry_collection
  has_many :registry_claims, dependent: :destroy
  validates :title, presence: true, length: { maximum: 180 }
  validates :quantity_requested, numericality: { greater_than: 0 }

  def available_quantity
    quantity_requested - registry_claims.where(status: %i[reserved purchased]).sum(:quantity)
  end

  def claim!(user, quantity: 1)
    with_lock do
      raise ActiveRecord::RecordInvalid.new(self), "Not enough remaining" if quantity > available_quantity

      claim = registry_claims.find_or_initialize_by(user:)
      claim.quantity = claim.reserved? || claim.purchased? ? claim.quantity + quantity : quantity
      claim.status = :reserved
      claim.save!
      claim
    end
  end
end
