class QuestionnaireResponse < ApplicationRecord
  belongs_to :questionnaire
  belongs_to :user, optional: true
  belongs_to :invitee, optional: true
  belongs_to :household, optional: true
  has_many :answers, class_name: "QuestionnaireAnswer", dependent: :destroy

  validate :has_one_respondent
  validate :respondent_belongs_to_questionnaire_site

  private

  def has_one_respondent
    errors.add(:base, "must identify one respondent") unless [ user_id, invitee_id, household_id ].compact.one?
  end

  def respondent_belongs_to_questionnaire_site
    return unless questionnaire
    return errors.add(:user, "must belong to this wedding site") if user && user.site_id != questionnaire.site_id
    return errors.add(:invitee, "must belong to this wedding site") if invitee && invitee.site_id != questionnaire.site_id
    return if household.blank? || household.site_id == questionnaire.site_id

    errors.add(:household, "must belong to this wedding site")
  end
end
