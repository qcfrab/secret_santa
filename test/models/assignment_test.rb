require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
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

  test "валидное назначение сохраняется успешно" do
    assert @assignment.valid?
    assert @assignment.persisted?
  end

  test "нельзя назначить одну и ту же партисипацию Сантой и получателем (self-assignment)" do
    assignment = Assignment.new(
      santa_participation: @santa_participation,
      giftee_participation: @santa_participation
    )
    assert_not assignment.valid?
    assert assignment.errors[:giftee_participation].present? || assignment.errors[:base].present?
  end

  test "партисипации должны принадлежать одному событию" do
    other_user = create_user
    other_event = Event.create!(name: "Другое событие", organizer: other_user)
    other_participation = other_event.participations.find_by!(user: other_user)

    invalid_assignment = Assignment.new(
      santa_participation: @santa_participation,
      giftee_participation: other_participation
    )
    assert_not invalid_assignment.valid?
    assert invalid_assignment.errors[:event].present? || invalid_assignment.errors[:base].present?
  end

  test "уникальность santa_participation_id" do
    third_user = create_user
    @event.join(third_user)
    third_participation = @event.participations.find_by!(user: third_user)

    duplicate_santa = Assignment.new(
      santa_participation: @santa_participation,
      giftee_participation: third_participation
    )
    assert_not duplicate_santa.valid?
    assert duplicate_santa.errors[:santa_participation_id].present?

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_santa.save!(validate: false)
    end
  end

  test "уникальность giftee_participation_id" do
    third_user = create_user
    @event.join(third_user)
    third_participation = @event.participations.find_by!(user: third_user)

    duplicate_giftee = Assignment.new(
      santa_participation: third_participation,
      giftee_participation: @giftee_participation
    )
    assert_not duplicate_giftee.valid?
    assert duplicate_giftee.errors[:giftee_participation_id].present?

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_giftee.save!(validate: false)
    end
  end

  test "делегирование и ассоциации santa, giftee и event" do
    assert_equal @santa, @assignment.santa
    assert_equal @giftee, @assignment.giftee
    assert_equal @event, @assignment.event
  end

  test "participant? возвращает true для санты и получателя, false для постороннего" do
    assert @assignment.participant?(@santa)
    assert @assignment.participant?(@giftee)
    assert_not @assignment.participant?(create_user)
    assert_not @assignment.participant?(nil)
  end

  test "giftee_wishes возвращает список желаний получателя" do
    wish = @giftee.wishes.create!(title: "Телескоп")
    assert_equal [wish], @assignment.giftee_wishes.to_a
  end

  test "chat_partner_name_for показывает имя получателя Санте и скрывает Санту от получателя" do
    assert_equal @giftee.display_name, @assignment.chat_partner_name_for(@santa)
    assert_equal "Тайный Санта", @assignment.chat_partner_name_for(@giftee)
    assert_nil @assignment.chat_partner_name_for(create_user)
  end

  test "каскадное удаление сообщений при удалении назначения" do
    message = @assignment.messages.create!(body: "Привет!", from_santa: true)
    assert_difference("Message.count", -1) do
      @assignment.destroy
    end
    assert_not Message.exists?(message.id)
  end
end
