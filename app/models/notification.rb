require 'uuid'

class Notification < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :message
  has_many :updates, :class_name => 'NotificationUpdate'

  before_save :generate_uuid, :unless => :uuid?

  validates :uuid, :uniqueness => true
  validates :enrollment_id, :presence => true
  validates :message_id, :presence => true, :uniqueness => { :scope => :enrollment_id }
  validates :delivery_date, :presence => true


  protected

  def generate_uuid
    write_attribute :uuid, UUID.generate
  end

end
