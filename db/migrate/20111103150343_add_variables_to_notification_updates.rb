class AddVariablesToNotificationUpdates < ActiveRecord::Migration
  def self.up
    add_column :notification_updates, :variables, :text
  end

  def self.down
    remove_column :notification_updates, :variables
  end
end
