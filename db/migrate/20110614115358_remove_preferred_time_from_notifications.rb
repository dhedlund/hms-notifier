class RemovePreferredTimeFromNotifications < ActiveRecord::Migration
  def self.up
    remove_column :notifications, :preferred_time
  end

  def self.down
    add_column :notifications, :preferred_time, :string
  end
end
