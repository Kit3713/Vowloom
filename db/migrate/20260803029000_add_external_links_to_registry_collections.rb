class AddExternalLinksToRegistryCollections < ActiveRecord::Migration[8.1]
  def change
    add_column :registry_collections, :external_registry_url, :string
    add_column :registry_collections, :charity_url, :string
    add_column :registry_collections, :cash_fund_url, :string
  end
end
