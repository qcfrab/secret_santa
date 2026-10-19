class AddImageUrlToWishes < ActiveRecord::Migration[8.1]
  def change
    add_column :wishes, :image_url, :string
  end
end
