class Invitee < ApplicationRecord
  belongs_to :site
  belongs_to :household, optional: true
  has_one :user, dependent: :nullify
  has_many :event_invitations, dependent: :destroy
  has_many :events, through: :event_invitations

  enum :attendance_status, { pending: 0, attending: 1, declined: 2 }, default: :pending

  validates :first_name, :last_name, presence: true, length: { maximum: 80 }

  def full_name
    [ first_name, last_name ].join(" ")
  end
end
