class RefactorAssignmentsAndMessages < ActiveRecord::Migration[8.1]
  def up
    # 1. Create the assignments table
    create_table :assignments do |t|
      t.references :santa_participation, null: false, foreign_key: { to_table: :participations }, index: { unique: true, name: "index_assignments_on_santa_participation_id" }
      t.references :giftee_participation, null: false, foreign_key: { to_table: :participations }, index: { unique: true, name: "index_assignments_on_giftee_participation_id" }
      t.timestamps
    end

    # Backfill assignments from participations if any exist with giftee_id
    if column_exists?(:participations, :giftee_id)
      execute <<-SQL.squish
        INSERT INTO assignments (santa_participation_id, giftee_participation_id, created_at, updated_at)
        SELECT p_santa.id, p_giftee.id, NOW(), NOW()
        FROM participations p_santa
        JOIN participations p_giftee ON p_giftee.event_id = p_santa.event_id AND p_giftee.user_id = p_santa.giftee_id
        WHERE p_santa.giftee_id IS NOT NULL
      SQL
    end

    # 2. Alter the participations table
    if foreign_key_exists?(:participations, column: :giftee_id)
      remove_foreign_key :participations, column: :giftee_id
    end

    if check_constraint_exists?(:participations, name: "participations_user_id_not_giftee_id")
      remove_check_constraint :participations, name: "participations_user_id_not_giftee_id"
    end

    if index_name_exists?(:participations, "index_participations_on_event_id_and_giftee_id")
      remove_index :participations, name: "index_participations_on_event_id_and_giftee_id"
    end

    if index_name_exists?(:participations, "index_participations_on_giftee_id")
      remove_index :participations, name: "index_participations_on_giftee_id"
    end

    if column_exists?(:participations, :giftee_id)
      remove_column :participations, :giftee_id
    end

    if index_name_exists?(:participations, "index_participations_on_event_id_and_user_id")
      remove_index :participations, name: "index_participations_on_event_id_and_user_id"
    end

    unless index_name_exists?(:participations, "index_participations_on_event_id")
      add_index :participations, :event_id, name: "index_participations_on_event_id"
    end

    unless index_name_exists?(:participations, "index_participations_on_user_id_and_event_id")
      add_index :participations, [:user_id, :event_id], unique: true, name: "index_participations_on_user_id_and_event_id"
    end

    # 3. Alter the messages table
    add_reference :messages, :assignment, foreign_key: true, index: { name: "index_messages_on_assignment_id" }

    if column_exists?(:messages, :participation_id)
      execute <<-SQL.squish
        UPDATE messages
        SET assignment_id = assignments.id
        FROM assignments
        WHERE assignments.santa_participation_id = messages.participation_id
      SQL

      remove_reference :messages, :participation, foreign_key: true
    end

    change_column_null :messages, :assignment_id, false
    change_column_default :messages, :from_santa, from: true, to: nil
  end

  def down
    change_column_default :messages, :from_santa, from: nil, to: true

    add_reference :messages, :participation, foreign_key: true

    execute <<-SQL.squish
      UPDATE messages
      SET participation_id = assignments.santa_participation_id
      FROM assignments
      WHERE messages.assignment_id = assignments.id
    SQL

    change_column_null :messages, :participation_id, false
    remove_reference :messages, :assignment, foreign_key: true

    remove_index :participations, name: "index_participations_on_user_id_and_event_id" if index_name_exists?(:participations, "index_participations_on_user_id_and_event_id")
    remove_index :participations, name: "index_participations_on_event_id" if index_name_exists?(:participations, "index_participations_on_event_id")

    add_index :participations, [:event_id, :user_id], unique: true, name: "index_participations_on_event_id_and_user_id"

    add_reference :participations, :giftee, foreign_key: { to_table: :users }, null: true
    add_index :participations, [:event_id, :giftee_id], unique: true, name: "index_participations_on_event_id_and_giftee_id"

    execute <<-SQL.squish
      UPDATE participations
      SET giftee_id = p_giftee.user_id
      FROM assignments
      JOIN participations p_giftee ON p_giftee.id = assignments.giftee_participation_id
      WHERE assignments.santa_participation_id = participations.id
    SQL

    add_check_constraint :participations, "user_id <> giftee_id", name: "participations_user_id_not_giftee_id"

    drop_table :assignments
  end
end
