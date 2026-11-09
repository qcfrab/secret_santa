class Message < ApplicationRecord
  belongs_to :assignment

  validates :body, presence: true, length: { maximum: 1000 }
  validates :from_santa, inclusion: { in: [true, false] }

  after_create_commit :broadcast_message

  scope :from_santa, -> { where(from_santa: true) }
  scope :from_giftee, -> { where(from_santa: false) }

  # Returns the User who sent the message
  def sender
    from_santa? ? assignment.santa : assignment.giftee
  end

  # Returns the User who receives the message
  def recipient
    from_santa? ? assignment.giftee : assignment.santa
  end

  def from_giftee?
    !from_santa?
  end

  private

  def broadcast_message
    broadcast_append_to assignment, target: "messages", partial: "messages/message", locals: { message: self }
  end
end
