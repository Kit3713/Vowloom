class CreateMediaLibrary < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.references :site, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :event, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.boolean :featured, null: false, default: false
      t.timestamps
    end

    create_table :media_assets do |t|
      t.references :site, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :post, foreign_key: true
      t.references :event, foreign_key: true
      t.text :caption
      t.string :credit
      t.integer :status, null: false, default: 0
      t.boolean :featured, null: false, default: false
      t.timestamps
    end

    create_table :album_items do |t|
      t.references :album, null: false, foreign_key: true
      t.references :media_asset, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :album_items, [ :album_id, :media_asset_id ], unique: true
  end
end
