# test/integration/secret_santa_test.rb
require "test_helper"

class SecretSantaTest < ActionDispatch::IntegrationTest
  describe "Secret Santa Web Application Integration" do
    # --------------------------------------------------------------------------
    # Database Cleanup & Fixture Isolation
    # Rails transactional tests (use_transactional_tests = true) automatically
    # wrap each test in a database transaction and roll back on completion.
    # --------------------------------------------------------------------------

    # ==========================================================================
    # 1. THE HAPPY PATH
    # ==========================================================================
    describe "Happy Path: Full Secret Santa Lifecycle" do
      let(:organizer) { create(:user) }
      let(:alice)     { create(:user) }
      let(:bob)       { create(:user) }

      it "allows a user to sign in, create an event, manage wishlist, invite friends, draw names, and chat" do
        # ----------------------------------------------------------------------
        # Step 1: User signs in
        # ----------------------------------------------------------------------
        sign_in organizer
        get root_path
        assert_response :success

        # ----------------------------------------------------------------------
        # Step 2: Creates a Secret Santa event
        # ----------------------------------------------------------------------
        get new_event_path
        assert_response :success

        assert_difference("Event.count", 1) do
          post events_path, params: {
            event: {
              name: "Winter Wonderland 2026",
              description: "Annual office gift exchange with hot cocoa!",
              budget: 50,
              exchange_date: 2.weeks.from_now.to_date
            }
          }
        end

        event = Event.last
        assert_redirected_to event_path(event)
        follow_redirect!
        assert_response :success
        assert_equal "Игра создана", flash[:notice]

        # Verify organizer is automatically added as the first participant
        assert_includes event.users, organizer
        assert_equal 1, event.participations.count
        assert event.waiting?
        assert_not_nil event.invite_code

        # ----------------------------------------------------------------------
        # Step 3: Adds items to their personal wishlist
        # ----------------------------------------------------------------------
        get new_wish_path
        assert_response :success

        assert_difference("Wish.count", 1) do
          post wishes_path, params: {
            wish: {
              title: "Mechanical Keyboard",
              description: "Tactile brown switches, ANSI layout",
              url: "https://example.com/keyboard"
            }
          }
        end

        wish = Wish.last
        assert_redirected_to wishes_path
        follow_redirect!
        assert_response :success
        assert_equal "Желание добавлено", flash[:notice]
        assert_equal organizer, wish.user
        assert_equal "Mechanical Keyboard", wish.title

        # ----------------------------------------------------------------------
        # Step 4: Invites / adds participants via the unique invite link
        # ----------------------------------------------------------------------
        # Participant 1 (Alice) signs in and joins
        sign_in alice
        get join_path(code: event.invite_code)
        assert_response :success

        assert_difference("event.participations.count", 1) do
          post join_path(code: event.invite_code)
        end
        assert_redirected_to event_path(event)
        follow_redirect!
        assert_equal "Вы в игре!", flash[:notice]
        assert_includes event.reload.users, alice

        # Participant 2 (Bob) signs in and joins
        sign_in bob
        assert_difference("event.participations.count", 1) do
          post join_path(code: event.invite_code)
        end
        assert_redirected_to event_path(event)
        follow_redirect!
        assert_equal "Вы в игре!", flash[:notice]
        assert_includes event.reload.users, bob

        # Ensure we now satisfy the minimum participant requirement (3 members)
        assert_equal 3, event.participations.count
        assert event.can_draw?

        # ----------------------------------------------------------------------
        # Step 5: Organizer triggers the random name draw
        # ----------------------------------------------------------------------
        sign_in organizer
        post draw_event_path(event)

        assert_redirected_to event_path(event)
        follow_redirect!
        assert_response :success
        assert_equal "Жеребьёвка проведена", flash[:notice]

        event.reload
        assert event.drawn?

        # Validate business logic rules of the draw:
        # Every participant must have a non-nil giftee and nobody is their own Santa
        event.participations.each do |participation|
          assert_not_nil participation.giftee, "Participant #{participation.user.nickname} has no giftee"
          assert_not_equal participation.user_id, participation.giftee_id, "Participant cannot be their own Secret Santa"
        end
        # Ensure all giftees are unique (everyone gets a gift)
        assert_equal 3, event.participations.map(&:giftee_id).uniq.size

        # ----------------------------------------------------------------------
        # Step 6: Sends a message in the event's anonymous chat
        # ----------------------------------------------------------------------
        organizer_participation = event.participations.find_by!(user: organizer)

        get participation_path(organizer_participation)
        assert_response :success

        chat_body = "Ho Ho Ho! I am your Secret Santa. Excited to surprise you!"
        assert_difference("organizer_participation.messages.count", 1) do
          post participation_messages_path(organizer_participation), params: {
            message: { body: chat_body }
          }
        end

        assert_redirected_to participation_path(organizer_participation)
        follow_redirect!
        assert_response :success

        message = organizer_participation.messages.last
        assert_equal chat_body, message.body
        assert_equal true, message.from_santa
        assert_equal organizer, message.sender
        assert_equal organizer_participation.giftee, message.recipient
      end
    end

    # ==========================================================================
    # 2. BRANCH / EDGE CASE 1: AUTHORIZATION FAILURE
    # ==========================================================================
    describe "Authorization Security & Access Control" do
      let(:victim)      { create(:user) }
      let(:attacker)    { create(:user) }
      let(:victim_wish) { create(:wish, user: victim, title: "Legitimate Gift") }

      let(:organizer)    { create(:user) }
      let(:participant)  { create(:user) }
      let(:unrelated)    { create(:user) }
      let(:event) do
        e = create(:event, organizer: organizer)
        e.join(participant)
        e
      end

      describe "Wishlist Isolation" do
        before { sign_in attacker }

        it "denies an attacker attempting to edit another user's wishlist item" do
          get edit_wish_path(victim_wish)
          assert_response :not_found
        end

        it "denies an attacker attempting to update another user's wishlist item" do
          wish = victim_wish
          patch wish_path(wish), params: {
            wish: { title: "Malicious Overwrite" }
          }
          assert_response :not_found
          assert_equal "Legitimate Gift", wish.reload.title
        end

        it "denies an attacker attempting to delete another user's wishlist item" do
          wish = victim_wish
          assert_no_difference("Wish.count") do
            delete wish_path(wish)
          end
          assert_response :not_found
          assert wish.reload.persisted?
        end
      end

      describe "Event Access & Ownership Controls" do
        it "prevents an unrelated user from viewing an event they do not belong to" do
          sign_in unrelated
          get event_path(event)
          assert_response :not_found
        end

        it "prevents a non-organizer participant from triggering the name draw" do
          # Add a 3rd member so participant count doesn't fail the guard
          third_member = create(:user)
          event.join(third_member)

          sign_in participant
          post draw_event_path(event)
          assert_response :not_found

          assert event.reload.waiting?
        end

        it "redirects unauthenticated guests trying to access protected event resources" do
          get events_path
          assert_redirected_to new_user_session_path

          post events_path, params: { event: { name: "Sneaky Event" } }
          assert_redirected_to new_user_session_path
        end
      end
    end

    # ==========================================================================
    # 3. BRANCH / EDGE CASE 2: BUSINESS LOGIC / STATE GUARDS
    # ==========================================================================
    describe "Business Logic & State Guards" do
      let(:organizer) { create(:user) }
      let(:event)     { create(:event, organizer: organizer) }

      before { sign_in organizer }

      describe "Premature Draw Prevention" do
        it "prevents name draw when the event has only 1 participant (organizer only)" do
          assert_equal 1, event.participations.count
          assert_not event.can_draw?

          post draw_event_path(event)

          assert_redirected_to event_path(event)
          follow_redirect!
          assert_equal "Нужно минимум 3 участника", flash[:alert]
          assert event.reload.waiting?
          assert_empty event.participations.where.not(giftee_id: nil)
        end

        it "prevents name draw when the event has only 2 participants" do
          friend = create(:user)
          event.join(friend)
          assert_equal 2, event.participations.count

          post draw_event_path(event)

          assert_redirected_to event_path(event)
          follow_redirect!
          assert_equal "Нужно минимум 3 участника", flash[:alert]
          assert event.reload.waiting?
        end
      end

      describe "State Transitions & Late Joining" do
        before do
          2.times { event.join(create(:user)) }
          assert_equal 3, event.participations.count
          event.draw!
        end

        it "prevents triggering the draw on an already drawn event" do
          post draw_event_path(event)

          assert_redirected_to event_path(event)
          follow_redirect!
          assert_equal "Нужно минимум 3 участника", flash[:alert]
          assert event.reload.drawn?
        end

        it "rejects latecomers attempting to join after the draw has concluded" do
          latecomer = create(:user)
          sign_in latecomer

          assert_no_difference("event.participations.count") do
            post join_path(code: event.invite_code)
          end

          assert_redirected_to root_path
          follow_redirect!
          assert_equal "Игра уже началась", flash[:alert]
          assert_not_includes event.reload.users, latecomer
        end
      end

      describe "Validation State Guards on Event Creation" do
        it "rejects invalid event attributes with 422 unprocessable entity" do
          assert_no_difference("Event.count") do
            post events_path, params: {
              event: { name: "", budget: -50 }
            }
          end

          assert_response :unprocessable_entity
        end
      end
    end

    # ==========================================================================
    # 4. BRANCH / EDGE CASE 3: CHAT SECURITY & EDGE INPUT
    # ==========================================================================
    describe "Chat Security & Input Validation" do
      let(:organizer) { create(:user) }
      let(:alice)     { create(:user) }
      let(:bob)       { create(:user) }
      let(:outsider)  { create(:user) }

      let(:event) do
        e = create(:event, organizer: organizer)
        e.join(alice)
        e.join(bob)
        e.draw!
        e
      end

      let(:participation) { event.participations.first }

      describe "Unauthorized Access to Chat Room" do
        it "denies an outsider attempting to view a chat room they are not a participant in" do
          sign_in outsider
          get participation_path(participation)
          assert_response :not_found
        end

        it "denies an outsider attempting to post a message into another user's chat" do
          sign_in outsider

          assert_no_difference("Message.count") do
            post participation_messages_path(participation), params: {
              message: { body: "I shouldn't be here!" }
            }
          end
          assert_response :not_found
        end

        it "denies a participant from posting into a pairing chat that does not involve them" do
          # Find a participation in the event where bob is neither Santa nor Giftee
          target_participation = event.participations.find do |p|
            p.user_id != bob.id && p.giftee_id != bob.id
          end
          assert_not_nil target_participation, "A disjoint pairing should exist in a 3-person circle"

          sign_in bob

          assert_no_difference("Message.count") do
            post participation_messages_path(target_participation), params: {
              message: { body: "Eavesdropping message" }
            }
          end
          assert_response :not_found
        end
      end

      describe "Chat Input Edge Cases & Validations" do
        let(:santa) { participation.user }

        before { sign_in santa }

        it "rejects an empty chat message" do
          assert_no_difference("Message.count") do
            post participation_messages_path(participation), params: {
              message: { body: "" }
            }
          end

          assert_redirected_to participation_path(participation)
        end

        it "rejects a whitespace-only chat message" do
          assert_no_difference("Message.count") do
            post participation_messages_path(participation), params: {
              message: { body: "    \n\t   " }
            }
          end

          assert_redirected_to participation_path(participation)
        end

        it "rejects messages exceeding the maximum allowed character limit (1000 characters)" do
          oversized_body = "A" * 1001

          assert_no_difference("Message.count") do
            post participation_messages_path(participation), params: {
              message: { body: oversized_body }
            }
          end

          assert_redirected_to participation_path(participation)
        end

        it "correctly assigns from_santa: false when giftee sends a reply message" do
          giftee = participation.giftee
          sign_in giftee

          assert_difference("participation.messages.count", 1) do
            post participation_messages_path(participation), params: {
              message: { body: "Thank you for being my Secret Santa!" }
            }
          end

          reply = participation.messages.last
          assert_equal false, reply.from_santa
          assert_equal giftee, reply.sender
          assert_equal santa, reply.recipient
        end
      end
    end
  end
end
