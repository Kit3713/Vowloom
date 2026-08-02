class KioskDisplay < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"

  enum :mode, { gallery: 0, information: 1, mixed: 2, slideshow: 3, schedule: 4 }, default: :mixed
  has_secure_token :access_token
  validates :name, presence: true, length: { maximum: 100 }
  validates :refresh_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 10, less_than_or_equal_to: 3600 }
end
