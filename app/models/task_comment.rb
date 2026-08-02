class TaskComment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2_000 }
  validate :user_belongs_to_task_site

  private

  def user_belongs_to_task_site
    return if user.blank? || task.blank? || user.site_id == task.group.site_id

    errors.add(:user, "must belong to this wedding site")
  end
end
