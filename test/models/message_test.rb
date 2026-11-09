require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @santa = create_user
    @giftee = create_user
    event = Event.create!(name: "Тест", organizer: @santa)
    event.join(@giftee)
    santa_part = event.participations.find_by!(user: @santa)
    giftee_part = event.participations.find_by!(user: @giftee)
    @assignment = Assignment.create!(santa_participation: santa_part, giftee_participation: giftee_part)
  end

  test "пустое сообщение невалидно" do
    assert_not Message.new(assignment: @assignment, from_santa: true, body: "").valid?
  end

  test "from_santa обязательно и должно быть булевым" do
    assert_not Message.new(assignment: @assignment, from_santa: nil, body: "Привет").valid?
  end

  test "from_santa? различает отправителей и адресатов" do
    from_santa = Message.create!(assignment: @assignment, from_santa: true, body: "Привет")
    from_giftee = Message.create!(assignment: @assignment, from_santa: false, body: "Кто ты?")
    assert from_santa.from_santa?
    assert_not from_giftee.from_santa?
    assert_equal @santa, from_santa.sender
    assert_equal @giftee, from_santa.recipient
    assert_equal @giftee, from_giftee.sender
    assert_equal @santa, from_giftee.recipient
  end

  test "транслирует сообщение через Action Cable после создания" do
    stream_name = Turbo::StreamsChannel.verified_stream_name(Turbo::StreamsChannel.signed_stream_name(@assignment))
    assert_broadcasts(stream_name, 1) do
      Message.create!(assignment: @assignment, from_santa: true, body: "Привет из Action Cable!")
    end
  end
end
