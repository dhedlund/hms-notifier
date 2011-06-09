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

ActiveRecord::Schema.define(:version => 20110609114104) do

  create_table "enrollments", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "phone_number"
    t.integer  "message_stream_id"
    t.string   "delivery_method"
    t.datetime "stream_start"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "enrollments", ["message_stream_id", "stream_start"], :name => "index_enrollments_on_message_stream_id_and_stream_start"
  add_index "enrollments", ["phone_number", "message_stream_id"], :name => "index_enrollments_on_phone_number_and_message_stream_id", :unique => true

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
  end

  add_index "messages", ["message_stream_id", "name"], :name => "index_messages_on_message_stream_id_and_name", :unique => true

end
