class RegistryCollection < ApplicationRecord
  belongs_to :site
  has_many :registry_items, dependent: :destroy
  enum :visibility, { everyone: 0, members_only: 1 }, default: :everyone
  validates :title, presence: true, length: { maximum: 180 }
end
