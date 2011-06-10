class AddPreferredTimeToEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :preferred_time, :string
  end

  def self.down
    remove_column :enrollments, :preferred_time
  end
end
