class AddSmsTextToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :sms_text, :string
  end

  def self.down
    remove_column :messages, :sms_text
  end
end
