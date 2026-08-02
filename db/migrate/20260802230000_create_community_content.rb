class CreateCommunityContent < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.references :site, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :event, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.integer :participation, null: false, default: 0
      t.timestamps
    end

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :group_memberships, [ :group_id, :user_id ], unique: true

    create_table :posts do |t|
      t.references :site, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :group, foreign_key: true
      t.references :event, foreign_key: true
      t.string :postable_type
      t.bigint :postable_id
      t.integer :space, null: false, default: 0
      t.integer :visibility, null: false, default: 0
      t.string :title
      t.text :body, null: false
      t.boolean :comments_enabled, null: false, default: true
      t.boolean :pinned, null: false, default: false
      t.datetime :published_at
      t.datetime :hidden_at
      t.timestamps
    end
    add_index :posts, [ :postable_type, :postable_id ]
    add_index :posts, [ :site_id, :space, :published_at ]

    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :hidden_at
      t.timestamps
    end

    create_table :tasks do |t|
      t.references :group, null: false, foreign_key: true
      t.references :assigned_user, foreign_key: { to_table: :users }
      t.references :event, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :due_on
      t.datetime :completed_at
      t.timestamps
    end
  end
end
