class Assignment < ApplicationRecord
  belongs_to :event
  belongs_to :santa, class_name: "User"
  belongs_to :giftee, class_name: "User"
  has_many :messages, dependent: :destroy

  validates :santa_id, uniqueness: { scope: :event_id }
  validate :santa_is_not_giftee

  def participant?(user)
    [santa_id, giftee_id].include?(user.id)
  end

  def giftee_wishes
    giftee.wishes
  end

  def chat_partner_name_for(user)
    user.id == santa_id ? giftee.display_name : "Тайный Санта"
  end

  private

  def santa_is_not_giftee
    errors.add(:giftee, "не может совпадать с дарителем") if santa_id == giftee_id
  end
end