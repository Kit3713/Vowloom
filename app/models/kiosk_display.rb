class KioskDisplay < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"
  belongs_to :questionnaire, optional: true

  enum :mode, { gallery: 0, information: 1, mixed: 2, slideshow: 3, schedule: 4, questionnaire_results: 5 }, default: :mixed
  has_secure_token :access_token
  validates :name, presence: true, length: { maximum: 100 }
  validates :refresh_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 10, less_than_or_equal_to: 3600 }
  validate :questionnaire_is_safe_for_results_display

  private

  def questionnaire_is_safe_for_results_display
    return unless questionnaire_results?

    if questionnaire.blank?
      errors.add(:questionnaire, "must be selected for the questionnaire-results preset")
    elsif questionnaire.site_id != site_id || !questionnaire.kiosk_displayable?
      errors.add(:questionnaire, "must be a published, site-wide aggregate-results questionnaire from this site")
    end
  end
end
