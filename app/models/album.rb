class Album < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"
  belongs_to :event, optional: true
  has_many :album_items, dependent: :destroy
  has_many :media_assets, through: :album_items
  has_many :group_resources, as: :resourceable, dependent: :destroy

  enum :visibility, { everyone: 0, members_only: 1 }, default: :members_only
  validates :title, presence: true, length: { maximum: 180 }
end
