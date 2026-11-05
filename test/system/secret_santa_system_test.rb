# test/system/secret_santa_system_test.rb
require "application_system_test_case"

class SecretSantaSystemTest < ApplicationSystemTestCase
  test "completes an end-to-end browser journey from event creation to name drawing" do
    organizer = create(:user)
    alice     = create(:user)
    bob       = create(:user)

    # 1. Sign in as organizer
    sign_in organizer
    visit root_path

    # 2. Create Event
    visit new_event_path
    fill_in "Название", with: "New Year Bash 2027"
    fill_in "Описание", with: "Secret gift exchange"
    fill_in "Бюджет подарка, ₽", with: "2500"
    click_on "Создать игру"

    assert_text "Игра создана"
    assert_text "New Year Bash 2027"
    event = Event.last

    # 3. Add personal wish
    visit new_wish_path
    fill_in "Название подарка", with: "Board game 'Catan'"
    fill_in "Описание (цвет, размер, пожелания)", with: "Base set with 5-6 player expansion"
    click_on "Сохранить желание"

    assert_text "Желание добавлено"
    assert_text "Board game 'Catan'"

    # 4. Friends join via invite URL
    sign_in alice
    visit join_path(code: event.invite_code)
    click_on "Участвовать"
    assert_text "Вы в игре!"

    sign_in bob
    visit join_path(code: event.invite_code)
    click_on "Участвовать"
    assert_text "Вы в игре!"

    # 5. Organizer triggers draw
    sign_in organizer
    visit event_path(event)
    assert_text "Участников: 3"
    click_on "🎲 Провести жеребьёвку"

    assert_text "Жеребьёвка проведена"
    assert event.reload.drawn?
  end
end
