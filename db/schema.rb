# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_20_113757) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "santa_id", null: false
    t.bigint "giftee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "giftee_id"], name: "index_assignments_on_event_id_and_giftee_id", unique: true
    t.index ["event_id", "santa_id"], name: "index_assignments_on_event_id_and_santa_id", unique: true
    t.index ["event_id"], name: "index_assignments_on_event_id"
    t.index ["giftee_id"], name: "index_assignments_on_giftee_id"
    t.index ["santa_id"], name: "index_assignments_on_santa_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "budget"
    t.date "exchange_date"
    t.string "invite_code"
    t.integer "status", default: 0, null: false
    t.bigint "organizer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_events_on_invite_code", unique: true
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.bigint "sender_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_messages_on_assignment_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "user_id"], name: "index_participations_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_participations_on_event_id"
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nickname", null: false
    t.index "lower((nickname)::text)", name: "index_users_on_lower_nickname", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wishes", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "url"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wishes_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "events"
  add_foreign_key "assignments", "users", column: "giftee_id"
  add_foreign_key "assignments", "users", column: "santa_id"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "messages", "assignments"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "participations", "events"
  add_foreign_key "participations", "users"
  add_foreign_key "wishes", "users"
end
