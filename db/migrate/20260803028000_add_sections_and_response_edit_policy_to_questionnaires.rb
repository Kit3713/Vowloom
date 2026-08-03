class AddSectionsAndResponseEditPolicyToQuestionnaires < ActiveRecord::Migration[8.1]
  def change
    add_column :questionnaires, :response_edit_policy, :integer, null: false, default: 0
    add_column :questions, :section, :string
    add_index :questions, [ :questionnaire_id, :section, :position ], name: "index_questions_on_questionnaire_section_and_position"
  end
end
