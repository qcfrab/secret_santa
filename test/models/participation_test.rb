require "test_helper"

class ParticipationTest < ActiveSupport::TestCase
  setup do
    @santa = create_user
    @giftee = create_user
    @event = Event.create!(name: "Тест", organizer: @santa)
    @event.join(@giftee)
    @santa_participation = @event.participations.find_by!(user: @santa)
    @giftee_participation = @event.participations.find_by!(user: @giftee)
    @assignment = Assignment.create!(
      santa_participation: @santa_participation,
      giftee_participation: @giftee_participation
    )
  end

  test "уникальность user_id в рамках события на уровне валидации" do
    duplicate_participation = Participation.new(event: @event, user: @santa)
    assert_not duplicate_participation.valid?
    assert duplicate_participation.errors[:user_id].present?
  end

  test "уникальность user_id в рамках события на уровне БД (уникальный индекс)" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Participation.connection.execute(
        "INSERT INTO participations (user_id, event_id, created_at, updated_at) VALUES (#{@santa.id}, #{@event.id}, NOW(), NOW())"
      )
    end
  end

  test "ассоциации связывают Санту и получателя через Assignment" do
    assert_equal @assignment, @santa_participation.assignment_as_santa
    assert_equal @assignment, @giftee_participation.assignment_as_giftee

    assert_equal @giftee_participation, @santa_participation.giftee_participation
    assert_equal @santa_participation, @giftee_participation.santa_participation

    assert_equal @giftee, @santa_participation.giftee
    assert_equal @santa, @giftee_participation.santa
  end

  test "participant? истинно для санты и получателя, ложно для чужого" do
    assert @santa_participation.participant?(@santa)
    assert @santa_participation.participant?(@giftee)
    assert_not @santa_participation.participant?(create_user)
  end

  test "giftee_wishes возвращает желания получателя" do
    wish = @giftee.wishes.create!(title: "Книга")
    assert_equal [wish], @santa_participation.giftee_wishes.to_a
  end

  test "chat_partner_name_for скрывает санту от получателя" do
    assert_equal @giftee.display_name, @santa_participation.chat_partner_name_for(@santa)
    assert_equal "Тайный Санта", @santa_participation.chat_partner_name_for(@giftee)
  end
end
