class AddThreadedMediaComments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :comments, :body, true
    add_reference :comments, :parent, foreign_key: { to_table: :comments }
    add_reference :media_assets, :comment, foreign_key: true
  end
end
