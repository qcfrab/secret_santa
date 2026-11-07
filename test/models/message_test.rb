require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

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

  test "транслирует сообщение через Action Cable после создания" do
    stream_name = Turbo::StreamsChannel.verified_stream_name(Turbo::StreamsChannel.signed_stream_name(@participation))
    assert_broadcasts(stream_name, 1) do
      Message.create!(participation: @participation, from_santa: true, body: "Привет из Action Cable!")
    end
  end
end
