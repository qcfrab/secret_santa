require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @santa = create_user
    @giftee = create_user
    event = Event.create!(name: "Тест", organizer: @santa)
    @assignment = Assignment.create!(event: event, santa: @santa, giftee: @giftee)
  end

  test "пустое сообщение невалидно" do
    assert_not Message.new(assignment: @assignment, sender: @santa, body: "").valid?
  end

  test "посторонний не может писать в чат" do
    assert_not Message.new(assignment: @assignment, sender: create_user, body: "Привет").valid?
  end

  test "from_santa? различает отправителей" do
    from_santa = Message.create!(assignment: @assignment, sender: @santa, body: "Привет")
    from_giftee = Message.create!(assignment: @assignment, sender: @giftee, body: "Кто ты?")
    assert from_santa.from_santa?
    assert_not from_giftee.from_santa?
  end
end