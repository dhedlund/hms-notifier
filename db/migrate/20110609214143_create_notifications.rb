class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.string   :uuid
      t.integer  :enrollment_id
      t.integer  :message_id
      t.date     :delivery_date
      t.string   :preferred_time
      t.datetime :delivered_at
      t.string   :status

      t.timestamps
    end

    add_index :notifications, :uuid, :unique => true
    add_index :notifications, [:enrollment_id, :message_id], :unique => true
  end

  def self.down
    drop_table :notifications
  end
end
