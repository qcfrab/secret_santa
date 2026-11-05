require "test_helper"

class WishTest < ActiveSupport::TestCase
  test "title не может быть nil" do
    wish = Wish.new(user: create_user, title: nil)
    assert_not wish.valid?
    assert_includes wish.errors[:title], "не может быть пустым"
  end
end
