class RemoveImageUrlFromWishes < ActiveRecord::Migration[8.1]
  def change
    remove_column :wishes, :image_url, :string
  end
end
