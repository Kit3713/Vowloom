class QuestionnaireAnswer < ApplicationRecord
  belongs_to :questionnaire_response
  belongs_to :question
  has_one_attached :file

  validates :question_id, uniqueness: { scope: :questionnaire_response_id }
  validate :file_is_supported

  private

  def file_is_supported
    return unless file.attached?
    return if file.byte_size <= 50.megabytes && file.content_type.in?([ "application/pdf", "image/png", "image/jpeg", "image/webp", "image/gif", "video/mp4", "video/webm", "video/quicktime" ])

    errors.add(:file, "must be a PDF, image, or supported video no larger than 50 MB")
  end
end
