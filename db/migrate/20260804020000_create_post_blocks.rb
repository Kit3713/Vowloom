class CreatePostBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :post_blocks do |t|
      t.references :post, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.integer :position, null: false, default: 1
      t.string :title
      t.text :body
      t.jsonb :settings, null: false, default: {}
      t.string :blockable_type
      t.bigint :blockable_id
      t.datetime :opens_at
      t.datetime :closes_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :post_blocks, [ :post_id, :position ]
    add_index :post_blocks, [ :blockable_type, :blockable_id ]

    create_table :post_block_responses do |t|
      t.references :post_block, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :payload, null: false, default: {}
      t.datetime :submitted_at, null: false
      t.timestamps
    end
    add_index :post_block_responses, [ :post_block_id, :user_id ], unique: true
  end
end
