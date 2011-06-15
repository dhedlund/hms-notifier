class RemovePhoneNumberUniqueness < ActiveRecord::Migration
  def self.up
    remove_index :enrollments, [:phone_number, :message_stream_id]
    add_index :enrollments, :phone_number
  end

  def self.down
    add_index :enrollments, [:phone_number, :message_stream_id], :unique => true
    remove_index :enrollments, :phone_number
  end
end
