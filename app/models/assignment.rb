class Assignment < ApplicationRecord
  belongs_to :santa_participation, class_name: "Participation"
  belongs_to :giftee_participation, class_name: "Participation"
  has_many :messages, dependent: :destroy

  has_one :santa, through: :santa_participation, source: :user
  has_one :giftee, through: :giftee_participation, source: :user

  delegate :event, to: :santa_participation, allow_nil: true

  validates :santa_participation_id, uniqueness: true
  validates :giftee_participation_id, uniqueness: true
  validate :prevent_self_assignment
  validate :same_event

  def santa
    association(:santa).loaded? ? association(:santa).target : santa_participation&.user
  end

  def giftee
    association(:giftee).loaded? ? association(:giftee).target : giftee_participation&.user
  end

  def participant?(user)
    return false unless user

    user.id == santa&.id || user.id == giftee&.id
  end

  def giftee_wishes
    giftee&.wishes || Wish.none
  end

  def chat_partner_name_for(user)
    return nil unless participant?(user)

    user.id == santa&.id ? giftee&.display_name : "Тайный Санта"
  end

  private

  def prevent_self_assignment
    is_same = (santa_participation_id.present? && santa_participation_id == giftee_participation_id) ||
              (santa_participation.present? && giftee_participation.present? && santa_participation == giftee_participation)

    if is_same
      errors.add(:giftee_participation, "не может совпадать с Сантой")
      errors.add(:santa_participation, "не может совпадать с получателем")
      errors.add(:base, "Santa and Giftee cannot be the same participation")
    end
  end

  def same_event
    return unless santa_participation && giftee_participation

    event_mismatch = (santa_participation.event_id.present? && giftee_participation.event_id.present? && santa_participation.event_id != giftee_participation.event_id) ||
                     (santa_participation.event.present? && giftee_participation.event.present? && santa_participation.event != giftee_participation.event)

    if event_mismatch
      errors.add(:event, "должно быть одинаковым для обоих участников")
      errors.add(:base, "Participations must belong to the same event")
    end
  end
end
