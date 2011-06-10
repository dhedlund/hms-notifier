class CreateNotificationUpdates < ActiveRecord::Migration
  def self.up
    create_table :notification_updates do |t|
      t.integer  :notification_id
      t.string   :action
      t.string   :first_name
      t.string   :phone_number
      t.string   :delivery_method
      t.string   :message_path
      t.date     :delivery_date
      t.date     :delivery_expires
      t.string   :preferred_time
      t.datetime :uploaded_at
      t.integer  :response_code

      t.timestamps
    end

    add_index :notification_updates, :notification_id
    add_index :notification_updates, :uploaded_at
  end

  def self.down
    drop_table :notification_updates
  end
end
