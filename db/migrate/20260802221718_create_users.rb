class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :login_identifier, null: false
      t.string :recovery_email
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :login_identifier, unique: true
  end
end
