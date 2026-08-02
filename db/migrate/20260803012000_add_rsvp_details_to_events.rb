class AddRsvpDetailsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :meal_options, :jsonb, null: false, default: []
    add_column :event_invitations, :meal_choice, :string
    add_column :event_invitations, :dietary_notes, :text
    add_column :event_invitations, :accessibility_notes, :text
  end
end
