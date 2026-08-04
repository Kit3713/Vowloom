class AddPostBlockToMediaAssets < ActiveRecord::Migration[8.1]
  def change
    add_reference :media_assets, :post_block, foreign_key: true, index: true
  end
end
