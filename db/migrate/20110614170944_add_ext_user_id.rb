class AddExtUserId < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :ext_user_id, :string
    add_column :notification_updates, :ext_user_id, :string
  end

  def self.down
    remove_column :enrollments, :ext_user_id
    remove_column :notification_updates
  end
end
