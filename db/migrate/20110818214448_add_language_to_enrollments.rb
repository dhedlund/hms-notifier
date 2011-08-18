class AddLanguageToEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :language, :string
  end

  def self.down
    remove_column :enrollments, :language
  end
end
