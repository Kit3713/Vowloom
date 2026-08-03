class CreateQuestionnaireAudiences < ActiveRecord::Migration[8.1]
  def change
    create_table :questionnaire_audiences do |t|
      t.references :questionnaire, null: false, foreign_key: true
      t.references :invitee, foreign_key: true
      t.references :household, foreign_key: true
      t.timestamps
    end

    add_check_constraint :questionnaire_audiences,
      "num_nonnulls(invitee_id, household_id) = 1",
      name: "questionnaire_audiences_one_target"
    add_index :questionnaire_audiences, [ :questionnaire_id, :invitee_id ],
      unique: true,
      where: "invitee_id IS NOT NULL",
      name: "index_questionnaire_audiences_on_questionnaire_and_invitee"
    add_index :questionnaire_audiences, [ :questionnaire_id, :household_id ],
      unique: true,
      where: "household_id IS NOT NULL",
      name: "index_questionnaire_audiences_on_questionnaire_and_household"
  end
end
