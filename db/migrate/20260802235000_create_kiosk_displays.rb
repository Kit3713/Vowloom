class CreateKioskDisplays < ActiveRecord::Migration[8.1]
  def change
    create_table :kiosk_displays do |t|
      t.references :site, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :access_token, null: false
      t.integer :mode, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.boolean :show_qr_placeholder, null: false, default: true
      t.timestamps
    end
    add_index :kiosk_displays, :access_token, unique: true
  end
end
