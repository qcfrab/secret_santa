require "test_helper"

class ParticipationTest < ActiveSupport::TestCase
  setup do
    @santa = create_user
    @giftee = create_user
    @event = Event.create!(name: "Тест", organizer: @santa)
    @participation = Participation.find_by(event: @event, user: @santa)
    @participation.update!(giftee: @giftee)
  end

  test "нельзя назначить себя получателем" do
    p = Participation.new(event: @event, user: @giftee, giftee: @giftee)
    assert_not p.valid?
  end

  test "бд не позволяет user_id == giftee_id (check constraint)" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Participation.connection.execute(
        "UPDATE participations SET giftee_id = user_id WHERE id = #{@participation.id}"
      )
    end
  end

  test "два санты не могут иметь одного получателя в одной игре (уникальный индекс)" do
    other_santa = create_user
    other_participation = @event.participations.create!(user: other_santa)
    other_participation.giftee = @giftee
    assert_not other_participation.valid?

    assert_raises(ActiveRecord::RecordNotUnique) do
      other_participation.update_column(:giftee_id, @giftee.id)
    end
  end

  test "participant? истинно для санты и получателя, ложно для чужого" do
    assert @participation.participant?(@santa)
    assert @participation.participant?(@giftee)
    assert_not @participation.participant?(create_user)
  end

  test "giftee_wishes возвращает желания получателя" do
    wish = @giftee.wishes.create!(title: "Книга")
    assert_equal [wish], @participation.giftee_wishes.to_a
  end

  test "chat_partner_name_for скрывает санту от получателя" do
    assert_equal @giftee.display_name, @participation.chat_partner_name_for(@santa)
    assert_equal "Тайный Санта", @participation.chat_partner_name_for(@giftee)
  end
end
