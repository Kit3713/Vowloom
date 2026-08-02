class CreateModerationReports < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_reports do |t|
      t.references :site, null: false, foreign_key: true
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, null: false, polymorphic: true
      t.text :reason
      t.integer :status, null: false, default: 0
      t.references :handled_by, foreign_key: { to_table: :users }
      t.datetime :handled_at
      t.timestamps
    end
    add_index :moderation_reports, [ :site_id, :status, :created_at ]
  end
end
