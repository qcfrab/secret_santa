class Message < ApplicationRecord
  belongs_to :participation

  validates :body, presence: true, length: { maximum: 1000 }
  validates :from_santa, inclusion: { in: [true, false] }

  scope :from_santa, -> { where(from_santa: true) }
  scope :from_giftee, -> { where(from_santa: false) }

  # Returns the User who sent the message
  def sender
    from_santa? ? participation.user : participation.giftee
  end

  # Returns the User who receives the message
  def recipient
    from_santa? ? participation.giftee : participation.user
  end

  def from_giftee?
    !from_santa?
  end
end
