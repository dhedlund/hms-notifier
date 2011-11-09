class AddVariablesToEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :variables, :text
  end

  def self.down
    remove_column :enrollments, :variables
  end
end
