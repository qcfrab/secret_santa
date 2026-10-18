class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :wishes, dependent: :destroy
  has_many :organized_events, class_name: "Event", foreign_key: :organizer_id, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :events, through: :participations

  def display_name
    email.split("@").first
  end
end
