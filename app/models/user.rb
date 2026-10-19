class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:login]
  has_many :wishes, dependent: :destroy
  has_many :organized_events, class_name: "Event", foreign_key: :organizer_id, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :events, through: :participations

  attr_writer :login

  def login
    @login || nickname || email
  end

  validates :nickname,
            presence: { message: "не может быть пустым" },
            uniqueness: { case_sensitive: false, message: "уже занят другим пользователем" },
            length: { minimum: 2, maximum: 30 },
            format: {
              with: /\A[a-zA-Z0-9_]+\z/,
              message: "может содержать только латинские буквы, цифры и знак подчеркивания"
            }

  def display_name
    nickname.presence || email.split("@").first
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(
        ["LOWER(nickname) = :value OR LOWER(email) = :value", { value: login.strip.downcase }]
      ).first
    elsif conditions.key?(:nickname) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end
end
