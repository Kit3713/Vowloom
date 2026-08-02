class RegistryClaim < ApplicationRecord
  belongs_to :registry_item
  belongs_to :user
  enum :status, { reserved: 0, purchased: 1, released: 2 }, default: :reserved
  validates :quantity, numericality: { greater_than: 0 }
end
