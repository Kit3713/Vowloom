class AddPayloadsToArchiveSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :archive_snapshots, :public_payload, :jsonb, null: false, default: {}
    add_column :archive_snapshots, :private_payload, :jsonb, null: false, default: {}
  end
end
