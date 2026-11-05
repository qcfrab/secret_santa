require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @santa = create_user
    @giftee = create_user
    event = Event.create!(name: "Тест", organizer: @santa)
    @participation = Participation.find_by(event: event, user: @santa)
    @participation.update!(giftee: @giftee)
  end

  test "пустое сообщение невалидно" do
    assert_not Message.new(participation: @participation, from_santa: true, body: "").valid?
  end

  test "from_santa? различает отправителей" do
    from_santa = Message.create!(participation: @participation, from_santa: true, body: "Привет")
    from_giftee = Message.create!(participation: @participation, from_santa: false, body: "Кто ты?")
    assert from_santa.from_santa?
    assert_not from_giftee.from_santa?
    assert_equal @santa, from_santa.sender
    assert_equal @giftee, from_giftee.sender
  end
end
