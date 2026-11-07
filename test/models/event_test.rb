require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @organizer = create_user
    @event = Event.create!(name: "Офис 2026", organizer: @organizer)
  end

  test "генерирует invite_code" do
    assert_equal 8, @event.invite_code.length
  end

  test "организатор автоматически становится участником" do
    assert_includes @event.users, @organizer
  end

  test "без названия невалиден" do
    assert_not Event.new(organizer: @organizer).valid?
  end

  # --- контекст: join
  test "join добавляет участника один раз" do
    user = create_user
    2.times { @event.join(user) }
    assert_equal 2, @event.participations.count
  end

  test "join после жеребьёвки возвращает false" do
    2.times { @event.join(create_user) }
    @event.draw!
    assert_not @event.join(create_user)
  end

  test "can_draw? ложно, пока меньше 3 участников" do
    assert_not @event.can_draw?
  end

  test "draw! создаёт назначение на каждого и меняет статус" do
    2.times { @event.join(create_user) }
    @event.draw!
    assert_equal 3, @event.participations.where.not(giftee_id: nil).count
    assert @event.drawn?
  end

  test "draw! никого не назначает самому себе, получатели уникальны" do
    4.times { @event.join(create_user) }
    @event.draw!
    assert @event.participations.none? { |p| p.user_id == p.giftee_id }
    assert_equal 5, @event.participations.map(&:giftee_id).uniq.size
  end

  test "draw! падает, если участников мало" do
    assert_raises(Event::DrawError) { @event.draw! }
  end

  test "draw! нельзя вызвать дважды" do
    2.times { @event.join(create_user) }
    @event.draw!
    assert_raises(Event::DrawError) { @event.draw! }
  end

  test "destroy каскадно удаляет участников и их сообщения" do
    2.times { @event.join(create_user) }
    @event.draw!
    participation = @event.participations.first
    message = participation.messages.create!(body: "Тестовое сообщение", from_santa: true)

    assert_difference("Event.count", -1) do
      assert_difference("Participation.count", -3) do
        assert_difference("Message.count", -1) do
          @event.destroy
        end
      end
    end

    assert_not Participation.exists?(participation.id)
    assert_not Message.exists?(message.id)
  end
end
