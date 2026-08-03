class AddRsvpDeadlineToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :rsvp_deadline, :datetime
  end
end
