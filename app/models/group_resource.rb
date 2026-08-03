class GroupResource < ApplicationRecord
  RESOURCE_TYPES = %w[Event Questionnaire Album MediaAsset].freeze

  belongs_to :group
  belongs_to :created_by, class_name: "User"
  belongs_to :resourceable, polymorphic: true

  validates :resourceable_type, inclusion: { in: RESOURCE_TYPES }
  validate :resource_belongs_to_group_site
  validate :approved_media

  def visible_to?(viewer)
    case resourceable
    when Event
      resourceable.visible_to?(viewer)
    when Questionnaire
      (resourceable.published? && resourceable.available_to?(viewer)) || resourceable.manageable_by?(viewer)
    when Album
      resourceable.everyone? || viewer.present?
    when MediaAsset
      resourceable.approved? && resourceable.accessible_to?(viewer)
    else
      false
    end
  end

  private

  def resource_belongs_to_group_site
    return unless group && resourceable.respond_to?(:site_id)
    return if resourceable.site_id == group.site_id

    errors.add(:resourceable, "must belong to this wedding site")
  end

  def approved_media
    return unless resourceable.is_a?(MediaAsset)
    return if resourceable.approved?

    errors.add(:resourceable, "must be approved before it can be pinned")
  end
end
