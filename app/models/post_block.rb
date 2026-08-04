class PostBlock < ApplicationRecord
  TYPES = %w[text media note sheet list questionnaire event_rsvp checklist signup file_resource location album].freeze
  MEDIA_FILE_TYPES = %w[image/png image/jpeg image/webp image/gif video/mp4 video/webm video/quicktime].freeze
  SAFE_FILE_TYPES = %w[
    application/pdf text/plain text/csv
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.oasis.opendocument.text application/vnd.oasis.opendocument.spreadsheet
    image/png image/jpeg image/webp image/gif video/mp4 video/webm video/quicktime
  ].freeze

  belongs_to :post
  belongs_to :created_by, class_name: "User"
  belongs_to :blockable, polymorphic: true, optional: true
  has_many :responses, class_name: "PostBlockResponse", dependent: :destroy
  has_many :media_assets, dependent: :destroy
  has_many_attached :files

  scope :ordered, -> { order(:position, :created_at) }

  TYPES.each do |type|
    define_method("#{type}?") { kind == type }
  end

  validates :kind, inclusion: { in: TYPES }
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :title, length: { maximum: 180 }, allow_blank: true
  validates :body, length: { maximum: 10_000 }, allow_blank: true
  validate :closes_after_opens
  validate :blockable_belongs_to_site
  validate :files_are_safe
  validate :files_fit_site_quota
  validate :element_has_content

  def options
    Array(settings["options"]).filter_map { |entry| entry.to_s.strip.presence }.uniq
  end

  def audience
    settings.fetch("audience", "members")
  end

  def results_visibility
    settings.fetch("results_visibility", "participants")
  end

  def editable_until_close?
    settings.fetch("response_edit_policy", "editable") == "editable"
  end

  def available_to?(user)
    visible_post = user ? post.accessible_to?(user) : post.everyone? && (!post.group_space? || post.group.site_wide?)
    return false unless visible_post
    return staff?(user) if audience == "staff"

    true
  end

  def open_for_responses?
    (opens_at.blank? || opens_at <= Time.current) && (closes_at.blank? || closes_at >= Time.current)
  end

  def response_editable?(response)
    interactive? && open_for_responses? && (response.blank? || editable_until_close?)
  end

  def results_visible_to?(user)
    return true if staff?(user)
    return false if results_visibility == "staff"

    results_visibility == "members" || responses.exists?(user:)
  end

  def response_counts
    responses.each_with_object(Hash.new(0)) do |response, counts|
      Array(response.payload["selections"]).each { |selection| counts[selection] += 1 }
    end
  end

  def capacity
    settings["capacity"].to_i.positive? ? settings["capacity"].to_i : nil
  end

  def interactive?
    ActiveModel::Type::Boolean.new.cast(settings["interactive"])
  end

  def sticky_note?
    note? || sheet? || list?
  end

  def contributable_by?(user)
    return false unless sticky_note? && available_to?(user)

    post.manageable_by?(user) || interactive?
  end

  def grid
    value = settings["grid"]
    return value if value.is_a?(Array) && value.any?

    Array.new(4) { Array.new(3, "") }
  end

  def list_items
    Array(settings["items"]).filter_map do |item|
      next unless item.is_a?(Hash) && item["text"].present?

      item
    end
  end

  def materialize_media!(site:, user:)
    return unless media?

    files.to_a.each do |attachment|
      asset = media_assets.build(
        site:,
        user:,
        post:,
        status: user.owner? || user.admin? || user.helper? ? :approved : :submitted
      )
      asset.file.attach(attachment.blob)
      attachment.destroy!
      asset.save!
    end
  end

  private

  def staff?(user)
    user&.owner? || user&.admin? || user&.helper?
  end

  def closes_after_opens
    errors.add(:closes_at, "must be after the opening time") if opens_at && closes_at && closes_at < opens_at
  end

  def blockable_belongs_to_site
    return unless blockable
    return if blockable.respond_to?(:site_id) && blockable.site_id == post&.site_id

    errors.add(:blockable, "must belong to this wedding site")
  end

  def files_are_safe
    errors.add(:files, "can include no more than 10 files") if files.length > 10
    allowed_types = media? ? MEDIA_FILE_TYPES : SAFE_FILE_TYPES
    files.each do |file|
      errors.add(:files, "must be a supported document, spreadsheet, presentation, image, or video") unless file.content_type.in?(allowed_types)
      errors.add(:files, "must each be 500 MB or smaller") if file.byte_size > 500.megabytes
    end
  end

  def files_fit_site_quota
    return unless post&.site && files.attached?
    return if post.site.media_bytes_used + files.sum(&:byte_size) <= post.site.media_quota_bytes

    errors.add(:files, "would exceed this wedding site's media storage limit")
  end

  def element_has_content
    errors.add(:body, "cannot be blank") if (text? || note?) && title.blank? && body.blank?
    errors.add(:files, "must include at least one file") if media? && !files.attached? && media_assets.empty?
    errors.add(:files, "must include at least one file") if file_resource? && !files.attached?
    errors.add(:blockable, "must be selected") if (questionnaire? || event_rsvp? || album?) && blockable.blank?
  end
end
