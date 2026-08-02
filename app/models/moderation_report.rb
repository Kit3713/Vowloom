class ModerationReport < ApplicationRecord
  belongs_to :site
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :handled_by, class_name: "User", optional: true

  enum :status, { open: 0, resolved: 1, dismissed: 2 }, default: :open

  validates :reason, length: { maximum: 1_000 }
  validate :reportable_belongs_to_site

  private

  def reportable_belongs_to_site
    return unless reportable.respond_to?(:site_id) && site_id != reportable.site_id

    errors.add(:reportable, "must belong to this wedding site")
  end
end
