class CreateGroupResources < ActiveRecord::Migration[8.1]
  def change
    # This guard makes a local checkout safe when the migration was renamed to
    # avoid a parallel branch's version collision after it had already run.
    return if table_exists?(:group_resources)

    create_table :group_resources do |t|
      t.references :group, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :resourceable, null: false, polymorphic: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :group_resources, [ :group_id, :resourceable_type, :resourceable_id ], unique: true,
      name: "index_group_resources_on_group_and_resource"
    add_index :group_resources, [ :group_id, :position, :created_at ]
  end
end
