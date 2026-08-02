class AddConversationToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :conversation, :boolean, null: false, default: false
    add_index :posts, [ :site_id, :conversation ], where: "conversation = true", unique: true, name: "index_posts_on_site_conversation"
  end
end
