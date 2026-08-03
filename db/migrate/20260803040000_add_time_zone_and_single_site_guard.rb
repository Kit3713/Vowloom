class AddTimeZoneAndSingleSiteGuard < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :time_zone, :string, null: false, default: "UTC"
  end
end
