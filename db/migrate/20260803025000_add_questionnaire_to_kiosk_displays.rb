class AddQuestionnaireToKioskDisplays < ActiveRecord::Migration[8.1]
  def change
    add_reference :kiosk_displays, :questionnaire, foreign_key: true
  end
end
