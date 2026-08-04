class AddPostTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :post_type, :integer, null: false, default: 0
    add_index :posts, [ :site_id, :post_type, :published_at ]
    change_column_null :posts, :body, true
  end
end
