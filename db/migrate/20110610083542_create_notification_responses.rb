class CreateNotificationResponses < ActiveRecord::Migration
  def self.up
    create_table :notification_responses do |t|
      t.integer  :notification_id
      t.string   :status
      t.string   :error_type
      t.text     :error_msg
      t.datetime :delivered_at

      t.timestamps

    end
  end

  def self.down
    drop_table :notification_responses
  end
end
