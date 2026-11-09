class Participation < ApplicationRecord
  belongs_to :event
  belongs_to :user

  has_one :assignment_as_santa, class_name: "Assignment", foreign_key: :santa_participation_id, dependent: :destroy, inverse_of: :santa_participation
  has_one :assignment_as_giftee, class_name: "Assignment", foreign_key: :giftee_participation_id, dependent: :destroy, inverse_of: :giftee_participation

  has_one :giftee_participation, through: :assignment_as_santa, source: :giftee_participation
  has_one :santa_participation, through: :assignment_as_giftee, source: :santa_participation

  has_one :giftee, through: :giftee_participation, source: :user
  has_one :santa, through: :santa_participation, source: :user

  validates :user_id, uniqueness: { scope: :event_id }

  def participant?(target_user)
    return false unless target_user

    target_user.id == user_id || target_user.id == giftee&.id || target_user.id == santa&.id
  end

  def giftee_wishes
    giftee&.wishes || Wish.none
  end

  def chat_partner_name_for(target_user)
    return nil unless participant?(target_user)

    target_user.id == user_id ? giftee&.display_name : "Тайный Санта"
  end
end
