class Task < ApplicationRecord
  belongs_to :group
  belongs_to :assigned_user, class_name: "User", optional: true
  belongs_to :event, optional: true
  has_many :task_comments, dependent: :destroy

  validates :title, presence: true, length: { maximum: 180 }
  validate :assigned_user_is_group_member

  def complete?
    completed_at.present?
  end

  private

  def assigned_user_is_group_member
    return if assigned_user.blank? || group.blank? || group.members.exists?(assigned_user.id)

    errors.add(:assigned_user, "must belong to the group")
  end
end
