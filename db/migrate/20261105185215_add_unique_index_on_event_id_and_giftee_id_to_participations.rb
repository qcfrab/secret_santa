class AddUniqueIndexOnEventIdAndGifteeIdToParticipations < ActiveRecord::Migration[8.1]
  def change
    add_index :participations, [:event_id, :giftee_id], unique: true
  end
end
