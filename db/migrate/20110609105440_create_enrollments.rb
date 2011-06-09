class CreateEnrollments < ActiveRecord::Migration
  def self.up
    create_table :enrollments do |t|
      t.string   :first_name
      t.string   :last_name
      t.integer  :phone_number
      t.integer  :message_stream_id
      t.string   :delivery_method
      t.datetime :stream_start

      t.timestamps
    end

    add_index :enrollments, [:phone_number, :message_stream_id], :unique => true
    add_index :enrollments, [:message_stream_id, :stream_start]
  end

  def self.down
    drop_table :enrollments
  end
end
