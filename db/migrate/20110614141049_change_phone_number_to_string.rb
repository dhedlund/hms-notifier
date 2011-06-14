class ChangePhoneNumberToString < ActiveRecord::Migration
  def self.up
    remove_index :enrollments, [:phone_number, :message_stream_id]
    change_column :enrollments, :phone_number, :string
    add_index :enrollments, [:phone_number, :message_stream_id], :unique => true
  end

  def self.down
    remove_index :enrollments, [:phone_number, :message_stream_id]
    change_column :enrollments, :phone_number, :integer
    add_index :enrollments, [:phone_number, :message_stream_id], :unique => true
  end
end
