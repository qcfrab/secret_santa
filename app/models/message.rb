class Message < ApplicationRecord
  belongs_to :assignment
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 1000 }
  validate :sender_is_participant

  def from_santa?
    sender_id == assignment.santa_id
  end

  private

  def sender_is_participant
    errors.add(:sender, "не участвует в этом чате") unless assignment&.participant?(sender)
  end
end