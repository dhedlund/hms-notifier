# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111103151858) do

  create_table "enrollments", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone_number"
    t.integer  "message_stream_id"
    t.string   "delivery_method"
    t.string   "preferred_time"
    t.date     "stream_start"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ext_user_id"
    t.string   "status"
    t.string   "language"
    t.text     "variables"
  end

  add_index "enrollments", ["message_stream_id"], :name => "index_enrollments_on_message_stream_id"
  add_index "enrollments", ["phone_number"], :name => "index_enrollments_on_phone_number"

  create_table "message_streams", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_streams", ["name"], :name => "index_message_streams_on_name", :unique => true

  create_table "messages", :force => true do |t|
    t.integer  "message_stream_id"
    t.string   "name"
    t.string   "title"
    t.integer  "offset_days"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sms_text"
    t.string   "language"
    t.integer  "expire_days"
  end

  add_index "messages", ["message_stream_id", "name"], :name => "index_messages_on_message_stream_id_and_name", :unique => true

  create_table "notification_responses", :force => true do |t|
    t.integer  "notification_id"
    t.string   "status"
    t.string   "error_type"
    t.text     "error_msg"
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_updates", :force => true do |t|
    t.integer  "notification_id"
    t.string   "action"
    t.string   "first_name"
    t.string   "phone_number"
    t.string   "delivery_method"
    t.string   "message_path"
    t.date     "delivery_date"
    t.date     "delivery_expires"
    t.string   "preferred_time"
    t.datetime "uploaded_at"
    t.integer  "response_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ext_user_id"
    t.text     "variables"
  end

  add_index "notification_updates", ["notification_id"], :name => "index_notification_updates_on_notification_id"
  add_index "notification_updates", ["uploaded_at"], :name => "index_notification_updates_on_uploaded_at"

  create_table "notifications", :force => true do |t|
    t.string   "uuid"
    t.integer  "enrollment_id"
    t.integer  "message_id"
    t.date     "delivery_date"
    t.datetime "delivered_at"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["enrollment_id", "message_id"], :name => "index_notifications_on_enrollment_id_and_message_id", :unique => true
  add_index "notifications", ["uuid"], :name => "index_notifications_on_uuid", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password"
    t.string   "timezone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
