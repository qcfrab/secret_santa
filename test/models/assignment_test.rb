require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  setup do
    @santa = create_user
    @giftee = create_user
    @event = Event.create!(name: "Тест", organizer: @santa)
    @assignment = Assignment.create!(event: @event, santa: @santa, giftee: @giftee)
  end

  test "нельзя назначить себя получателем" do
    a = Assignment.new(event: @event, santa: @giftee, giftee: @giftee)
    assert_not a.valid?
  end

  test "participant? истинно для санты и получателя, ложно для чужого" do
    assert @assignment.participant?(@santa)
    assert @assignment.participant?(@giftee)
    assert_not @assignment.participant?(create_user)
  end

  test "giftee_wishes возвращает желания получателя" do
    wish = @giftee.wishes.create!(title: "Книга")
    assert_equal [wish], @assignment.giftee_wishes.to_a
  end

  test "chat_partner_name_for скрывает санту от получателя" do
    assert_equal @giftee.display_name, @assignment.chat_partner_name_for(@santa)
    assert_equal "Тайный Санта", @assignment.chat_partner_name_for(@giftee)
  end
end