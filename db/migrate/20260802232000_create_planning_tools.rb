class CreatePlanningTools < ActiveRecord::Migration[8.1]
  def change
    create_table :questionnaires do |t|
      t.references :site, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :group, foreign_key: true
      t.references :event, foreign_key: true
      t.string :title, null: false
      t.text :introduction
      t.integer :status, null: false, default: 0
      t.integer :response_scope, null: false, default: 0
      t.integer :results_visibility, null: false, default: 0
      t.datetime :opens_at
      t.datetime :closes_at
      t.timestamps
    end
    create_table :questions do |t|
      t.references :questionnaire, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :kind, null: false
      t.text :prompt, null: false
      t.boolean :required, null: false, default: false
      t.jsonb :options, null: false, default: []
      t.jsonb :conditional_rule, null: false, default: {}
      t.timestamps
    end
    add_index :questions, [ :questionnaire_id, :position ], unique: true
    create_table :questionnaire_responses do |t|
      t.references :questionnaire, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :invitee, foreign_key: true
      t.references :household, foreign_key: true
      t.datetime :submitted_at
      t.timestamps
    end
    create_table :questionnaire_answers do |t|
      t.references :questionnaire_response, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.jsonb :value, null: false, default: {}
      t.timestamps
    end
    add_index :questionnaire_answers, [ :questionnaire_response_id, :question_id ], unique: true, name: "index_questionnaire_answers_on_response_and_question"
    create_table :registry_collections do |t|
      t.references :site, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.boolean :published, null: false, default: false
      t.timestamps
    end
    create_table :registry_items do |t|
      t.references :registry_collection, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :external_url
      t.string :currency, null: false, default: "USD"
      t.integer :price_cents
      t.integer :quantity_requested, null: false, default: 1
      t.integer :priority, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    create_table :registry_claims do |t|
      t.references :registry_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.datetime :purchased_at
      t.timestamps
    end
    add_index :registry_claims, [ :registry_item_id, :user_id ], unique: true
  end
end
