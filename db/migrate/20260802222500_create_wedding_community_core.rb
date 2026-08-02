class CreateWeddingCommunityCore < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.date :wedding_date
      t.integer :access_policy, null: false, default: 0
      t.integer :content_state, null: false, default: 0
      t.text :landing_message
      t.string :accent_color, null: false, default: "#8f4f6a"
      t.timestamps
    end

    create_table :households do |t|
      t.references :site, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    create_table :invitees do |t|
      t.references :site, null: false, foreign_key: true
      t.references :household, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.integer :attendance_status, null: false, default: 0
      t.timestamps
    end

    add_reference :users, :site, foreign_key: true
    add_reference :users, :invitee, foreign_key: true, index: { unique: true }
    add_column :users, :role, :integer, null: false, default: 3
    add_column :users, :display_name, :string, null: false, default: ""
    add_column :users, :profile_summary, :text

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    create_table :invitation_codes do |t|
      t.references :site, null: false, foreign_key: true
      t.references :household, foreign_key: true
      t.string :code_digest, null: false
      t.datetime :expires_at
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :invitation_codes, :code_digest, unique: true

    create_table :events do |t|
      t.references :site, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :location_name
      t.text :location_address
      t.string :map_url
      t.integer :visibility, null: false, default: 0
      t.timestamps
    end

    create_table :event_invitations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :invitee, null: false, foreign_key: true
      t.integer :rsvp_status, null: false, default: 0
      t.datetime :responded_at
      t.timestamps
    end
    add_index :event_invitations, [ :event_id, :invitee_id ], unique: true
  end
end
