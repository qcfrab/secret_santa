class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :santa, null: false, foreign_key: { to_table: :users }
      t.references :giftee, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :assignments, [:event_id, :santa_id], unique: true
    add_index :assignments, [:event_id, :giftee_id], unique: true
  end
end
