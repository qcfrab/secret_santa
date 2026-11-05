# test/factories.rb

FactoryBot.define do
  sequence(:email)    { |n| "user_#{n}@example.com" }

  sequence(:nickname) { |n| "santa_#{n}" }

  sequence :event_name do |n|
    "Secret Santa Party #{n}"
  end

  sequence :wish_title do |n|
    "Holiday Gift #{n}"
  end

  factory :user do
    email { FactoryBot.generate(:email) }
    nickname { FactoryBot.generate(:nickname) }
    password { "password123" }
    password_confirmation { "password123" }
  end

  factory :event do
    name { FactoryBot.generate(:event_name) }
    description { "Annual holiday exchange event" }
    budget { 50 }
    exchange_date { Date.today + 14.days }
    organizer { FactoryBot.create(:user) }
  end

  factory :wish do
    user { FactoryBot.create(:user) }
    title { FactoryBot.generate(:wish_title) }
    description { "Something cozy and thoughtful" }
    url { "https://example.com/gifts" }
  end

  factory :participation do
    event { FactoryBot.create(:event) }
    user { FactoryBot.create(:user) }
  end

  factory :message do
    participation { FactoryBot.create(:participation) }
    body { "Ho ho ho! Looking forward to giving your gift!" }
    from_santa { true }
  end
end
