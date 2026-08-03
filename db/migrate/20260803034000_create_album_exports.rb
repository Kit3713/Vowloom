class CreateAlbumExports < ActiveRecord::Migration[8.1]
  def change
    create_table :album_exports do |t|
      t.references :album, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.boolean :include_originals, null: false, default: false
      t.jsonb :media_asset_ids, null: false, default: []
      t.integer :media_count, null: false, default: 0
      t.text :error_message
      t.datetime :completed_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :album_exports, [ :album_id, :status, :created_at ]
    add_index :album_exports, :expires_at
  end
end
