class Event < ApplicationRecord
  class DrawError < StandardError; end
  MIN_PARTICIPANTS = 3

  belongs_to :organizer, class_name: "User"
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :assignments, dependent: :destroy

  enum :status, { waiting: 0, drawn: 1 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :budget, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :invite_code, uniqueness: true

  before_validation :generate_invite_code, on: :create
  after_create :add_organizer_as_participant

  def can_draw?
    waiting? && participations.count >= MIN_PARTICIPANTS
  end

  def join(user)
    return false if drawn?
    participations.find_or_create_by(user: user).persisted?
  end

  def draw!
    raise DrawError, "Нужно минимум #{MIN_PARTICIPANTS} участника" unless can_draw?

    transaction do
      santas = users.to_a.shuffle
      santas.each_with_index do |santa, i|
        assignments.create!(santa: santa, giftee: santas[(i + 1) % santas.size])
      end
      drawn!
    end
  end

  private

  def generate_invite_code
    self.invite_code ||= SecureRandom.alphanumeric(8).downcase
  end

  def add_organizer_as_participant
    participations.create!(user: organizer)
  end
end