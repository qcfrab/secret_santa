require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = create(:user)
    @alice = create(:user)
    @bob = create(:user)
    @event = create(:event, organizer: @organizer)
    @event.join(@alice)
    @event.join(@bob)
    @event.draw!
    @participation = @event.participations.first
    @message = create(:message, participation: @participation, body: "Hello Santa")
  end

  test "creator can delete the event and its dependent records" do
    sign_in @organizer
    event_id = @event.id
    participation_ids = @event.participation_ids
    message_id = @message.id

    assert_difference("Event.count", -1) do
      assert_difference("Participation.count", -3) do
        assert_difference("Message.count", -1) do
          delete event_path(@event)
        end
      end
    end

    assert_redirected_to events_path
    assert_response :see_other
    assert_equal "Игра удалена", flash[:notice]

    assert_not Event.exists?(event_id)
    assert_empty Participation.where(id: participation_ids)
    assert_not Message.exists?(message_id)
  end

  test "creator deletion supports turbo_stream format" do
    sign_in @organizer

    assert_difference("Event.count", -1) do
      delete event_path(@event), as: :turbo_stream
    end

    assert_redirected_to events_path
    assert_response :see_other
  end

  test "non-creator participant is forbidden from deleting the event" do
    sign_in @alice

    assert_no_difference("Event.count") do
      delete event_path(@event)
    end

    assert_response :not_found
    assert @event.reload.persisted?
  end

  test "unrelated user is forbidden from deleting the event" do
    outsider = create(:user)
    sign_in outsider

    assert_no_difference("Event.count") do
      delete event_path(@event)
    end

    assert_response :not_found
    assert @event.reload.persisted?
  end

  test "unauthenticated user is forbidden from deleting the event" do
    assert_no_difference("Event.count") do
      delete event_path(@event)
    end

    assert_redirected_to new_user_session_path
    assert @event.reload.persisted?
  end

  test "show view renders delete button and custom confirmation modal for creator" do
    sign_in @organizer
    get event_path(@event)
    assert_response :success

    assert_select "button.btn.btn-danger.btn-sm", text: "Удалить игру"
    assert_select "dialog#delete-modal.modal-dialog" do
      assert_select "p.modal-body", text: "Вы уверены, что хотите удалить игру? Это действие нельзя отменить."
      assert_select "button", text: "Отмена"
      assert_select "form.button_to[action=?]", event_path(@event) do
        assert_select "button.btn.btn-danger.btn-sm", text: "Удалить"
      end
    end
    assert_select "[data-turbo-confirm]", count: 0
  end

  test "show view does not render delete button or modal for non-creator participant" do
    sign_in @alice
    get event_path(@event)
    assert_response :success

    assert_select "button", text: "Удалить игру", count: 0
    assert_select "dialog#delete-modal", count: 0
    assert_select "form.button_to[action=?]", event_path(@event), count: 0
  end

  test "index view shows games list and general create button when user has games" do
    sign_in @organizer
    get events_path
    assert_response :success

    assert_select ".events-grid"
    assert_select ".page-header a.btn.btn-primary[href=?]", new_event_path, text: "+ Создать игру", count: 1
    assert_select ".card h3", text: "У вас пока нет активных игр", count: 0
  end

  test "index view shows only one create button inside empty state when user has no games" do
    new_user = create(:user)
    sign_in new_user
    get events_path
    assert_response :success

    assert_select ".events-grid", count: 0
    assert_select ".page-header a.btn.btn-primary", count: 0
    assert_select ".card a.btn.btn-primary[href=?]", new_event_path, text: "Создать игру", count: 1
    assert_select "a[href=?]", new_event_path, count: 1
  end
end
