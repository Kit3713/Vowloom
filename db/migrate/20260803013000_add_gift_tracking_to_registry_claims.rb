class AddGiftTrackingToRegistryClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :registry_claims, :received_at, :datetime
    add_column :registry_claims, :thank_you_sent_at, :datetime
    add_column :registry_claims, :private_note, :text
  end
end
