class Household < ApplicationRecord
  belongs_to :site
  has_many :invitees, dependent: :nullify
  has_many :invitation_codes, dependent: :destroy

  validates :name, presence: true, length: { maximum: 120 }
end
