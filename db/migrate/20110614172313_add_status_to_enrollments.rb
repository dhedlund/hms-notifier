class AddStatusToEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :status, :string
  end

  def self.down
    remove_column :enrollments, :status
  end
end
