require 'uuid'

class Notification < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :message
  has_many :updates, :class_name => 'NotificationUpdate'
  has_many :responses, :class_name => 'NotificationResponse'

  before_save :generate_uuid, :unless => :uuid?

  validates :uuid, :uniqueness => true
  validates :enrollment_id, :presence => true
  validates :message_id, :presence => true, :uniqueness => { :scope => :enrollment_id }
  validates :delivery_date, :presence => true

  alias_method :orig_enrollment=, :enrollment=
  def enrollment=(value)
    self.orig_enrollment=(value)
    self.preferred_time = enrollment.try(:preferred_time)
  end

  def delivery_date
    self[:delivery_date] ||= calc_delivery_date
  end


  protected

  def calc_delivery_date
    self[:delivery_date] = nil
    if enrollment && message
      self[:delivery_date] = enrollment.stream_start + message.offset_days
    end
  end

  def generate_uuid
    write_attribute :uuid, UUID.generate
  end

end
