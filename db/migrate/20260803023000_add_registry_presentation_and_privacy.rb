class AddRegistryPresentationAndPrivacy < ActiveRecord::Migration[8.1]
  def change
    add_column :registry_items, :category, :string
    add_column :registry_claims, :purchaser_revealed_at, :datetime

    add_index :registry_items, :category
  end
end
