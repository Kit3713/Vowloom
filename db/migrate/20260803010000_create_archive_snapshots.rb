class CreateArchiveSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :archive_snapshots do |t|
      t.references :site, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :manifest_version, null: false, default: 1
      t.jsonb :content_counts, null: false, default: {}
      t.string :checksum, null: false
      t.datetime :frozen_at, null: false
      t.timestamps
    end
  end
end
