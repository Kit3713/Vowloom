class AddMediaQuotaToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :media_quota_bytes, :bigint, null: false, default: 20.gigabytes
  end
end
