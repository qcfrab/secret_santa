class RefactorSecretSantaSchema < ActiveRecord::Migration[8.1]
  def up
    # 1. Add giftee_id to participations
    add_reference :participations, :giftee, foreign_key: { to_table: :users }, null: true

    # Backfill participations.giftee_id from existing assignments if assignments exists
    if table_exists?(:assignments)
      execute <<-SQL.squish
        UPDATE participations
        SET giftee_id = assignments.giftee_id
        FROM assignments
        WHERE assignments.event_id = participations.event_id
          AND assignments.santa_id = participations.user_id
      SQL
    end

    # 2. Update messages table
    add_reference :messages, :participation, foreign_key: true
    add_column :messages, :from_santa, :boolean, default: true, null: false

    # Backfill messages with participation_id and from_santa if assignments exists
    if table_exists?(:assignments) && column_exists?(:messages, :assignment_id)
      execute <<-SQL.squish
        UPDATE messages
        SET participation_id = participations.id,
            from_santa = (messages.sender_id = assignments.santa_id)
        FROM assignments
        JOIN participations ON participations.event_id = assignments.event_id AND participations.user_id = assignments.santa_id
        WHERE messages.assignment_id = assignments.id
      SQL
    end

    # Ensure all messages have participation_id, then set null: false
    change_column_null :messages, :participation_id, false

    # Remove old columns and foreign keys from messages
    remove_reference :messages, :assignment, foreign_key: true if column_exists?(:messages, :assignment_id)
    remove_reference :messages, :sender, foreign_key: { to_table: :users } if column_exists?(:messages, :sender_id)

    # 3. Drop assignments table
    drop_table :assignments if table_exists?(:assignments)

    # 4. Remove redundant B-tree index on participations
    remove_index :participations, :event_id, name: :index_participations_on_event_id if index_name_exists?(:participations, :index_participations_on_event_id)

    # 5. Add check constraint on participations (user_id != giftee_id)
    add_check_constraint :participations, "user_id != giftee_id", name: "participations_user_id_not_giftee_id"

    # 6. Add NOT NULL constraints
    change_column_null :wishes, :title, false
    change_column_null :messages, :body, false
    change_column_null :events, :invite_code, false
  end

  def down
    # 6. Revert NOT NULL constraints
    change_column_null :events, :invite_code, true
    change_column_null :messages, :body, true
    change_column_null :wishes, :title, true

    # 5. Remove check constraint
    remove_check_constraint :participations, name: "participations_user_id_not_giftee_id"

    # 4. Restore redundant index on participations
    add_index :participations, :event_id, name: :index_participations_on_event_id unless index_name_exists?(:participations, :index_participations_on_event_id)

    # 3. Restore assignments table
    create_table :assignments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :santa, null: false, foreign_key: { to_table: :users }
      t.references :giftee, null: false, foreign_key: { to_table: :users }
      t.timestamps
      t.index [:event_id, :santa_id], unique: true
      t.index [:event_id, :giftee_id], unique: true
    end

    # Backfill assignments from participations
    execute <<-SQL.squish
      INSERT INTO assignments (event_id, santa_id, giftee_id, created_at, updated_at)
      SELECT event_id, user_id, giftee_id, NOW(), NOW()
      FROM participations
      WHERE giftee_id IS NOT NULL
    SQL

    # 2. Revert messages table changes
    add_reference :messages, :assignment, foreign_key: true
    add_reference :messages, :sender, foreign_key: { to_table: :users }

    execute <<-SQL.squish
      UPDATE messages
      SET assignment_id = assignments.id,
          sender_id = CASE WHEN messages.from_santa THEN participations.user_id ELSE participations.giftee_id END
      FROM participations
      JOIN assignments ON assignments.event_id = participations.event_id AND assignments.santa_id = participations.user_id
      WHERE messages.participation_id = participations.id
    SQL

    change_column_null :messages, :assignment_id, false
    change_column_null :messages, :sender_id, false

    remove_column :messages, :from_santa
    remove_reference :messages, :participation, foreign_key: true

    # 1. Remove giftee_id from participations
    remove_reference :participations, :giftee, foreign_key: { to_table: :users }
  end
end
