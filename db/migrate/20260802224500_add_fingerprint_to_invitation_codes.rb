class AddFingerprintToInvitationCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :invitation_codes, :code_fingerprint, :string
    add_index :invitation_codes, :code_fingerprint, unique: true
  end
end
