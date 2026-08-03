class AddImportantAnnouncementDelivery < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :important_announcement_emails, :boolean, default: false, null: false

    add_column :posts, :important_announcement, :boolean, default: false, null: false
    add_column :posts, :announcement_email_queued_at, :datetime

    create_table :announcement_deliveries do |t|
      t.references :post, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :attempted_at
      t.datetime :delivered_at
      t.datetime :failed_at
      t.string :failure_reason
      t.timestamps
    end
    add_index :announcement_deliveries, [ :post_id, :recipient_id ], unique: true
    add_index :announcement_deliveries, [ :status, :created_at ]
  end
end
