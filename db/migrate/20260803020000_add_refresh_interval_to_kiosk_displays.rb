class AddRefreshIntervalToKioskDisplays < ActiveRecord::Migration[8.1]
  def change
    add_column :kiosk_displays, :refresh_seconds, :integer, null: false, default: 60
  end
end
