class AllowGroupConversations < ActiveRecord::Migration[8.1]
  def change
    remove_index :posts, name: "index_posts_on_site_conversation"
    add_index :posts, :site_id, unique: true, where: "conversation = true AND group_id IS NULL", name: "index_posts_on_global_conversation"
    add_index :posts, :group_id, unique: true, where: "conversation = true AND group_id IS NOT NULL", name: "index_posts_on_group_conversation"
  end
end
