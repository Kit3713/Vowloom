class EnforceOneOwnerPerSite < ActiveRecord::Migration[8.1]
  def up
    # Older installations may have been managed before ownership was enforced.
    # Preserve the earliest owner and make any additional owners administrators
    # before adding the database constraint.
    execute <<~SQL.squish
      WITH ranked_owners AS (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY site_id ORDER BY created_at, id) AS position
        FROM users
        WHERE role = 0
      )
      UPDATE users
      SET role = 1
      FROM ranked_owners
      WHERE users.id = ranked_owners.id AND ranked_owners.position > 1
    SQL

    add_index :users, :site_id,
      unique: true,
      where: "role = 0",
      name: "index_users_on_one_owner_per_site"
  end

  def down
    remove_index :users, name: "index_users_on_one_owner_per_site"
  end
end
