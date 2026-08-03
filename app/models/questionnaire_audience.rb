class QuestionnaireAudience < ApplicationRecord
  belongs_to :questionnaire
  belongs_to :invitee, optional: true
  belongs_to :household, optional: true

  validate :has_exactly_one_target
  validate :target_belongs_to_questionnaire_site

  def label
    invitee ? invitee.full_name : household.name
  end

  private

  def has_exactly_one_target
    errors.add(:base, "must select exactly one person or household") unless [ invitee_id, household_id ].compact.one?
  end

  def target_belongs_to_questionnaire_site
    return unless questionnaire

    if invitee && invitee.site_id != questionnaire.site_id
      errors.add(:invitee, "must belong to this wedding site")
    end
    if household && household.site_id != questionnaire.site_id
      errors.add(:household, "must belong to this wedding site")
    end
  end
end
