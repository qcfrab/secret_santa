class Participation < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :giftee, class_name: "User", optional: true

  has_many :messages, dependent: :destroy

  validates :user_id, uniqueness: { scope: :event_id }
  validates :giftee_id, uniqueness: { scope: :event_id }, allow_nil: true
  validate :santa_is_not_giftee

  alias_method :santa, :user

  def participant?(user)
    return false unless user

    user.id == user_id || user.id == giftee_id
  end

  def giftee_wishes
    giftee&.wishes || Wish.none
  end

  def chat_partner_name_for(user)
    return nil unless participant?(user)

    user.id == user_id ? giftee&.display_name : "Тайный Санта"
  end

  private

  def santa_is_not_giftee
    errors.add(:giftee, "не может совпадать с дарителем") if giftee_id.present? && user_id == giftee_id
  end
end
