class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.integer :budget
      t.date :exchange_date
      t.string :invite_code
      t.integer :status, default: 0, null: false
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :events, :invite_code, unique: true
  end
end
