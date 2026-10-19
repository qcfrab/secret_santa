class AddUniqueIndexToUsersNickname < ActiveRecord::Migration[8.0]
  def up
    User.where(nickname: [nil, ""]).find_each do |user|
      base_nick = user.email.split("@").first
      nick = base_nick
      counter = 1
      while User.where("LOWER(nickname) = ?", nick.downcase).where.not(id: user.id).exists?
        nick = "#{base_nick}_#{counter}"
        counter += 1
      end
      user.update_columns(nickname: nick)
    end

    change_column_null :users, :nickname, false
    add_index :users, "LOWER(nickname)", unique: true, name: "index_users_on_lower_nickname"
  end

  def down
    remove_index :users, name: "index_users_on_lower_nickname"
    change_column_null :users, :nickname, true
  end
end