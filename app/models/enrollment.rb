class Enrollment < ActiveRecord::Base
  belongs_to :message_stream
  has_many :notifications

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :phone_number, :presence => true
  validates :delivery_method, :presence => true
  validates :stream_start, :presence => true

  def ready_messages
    offset_days = (Date.today - stream_start).to_i
    possible = message_stream.messages.notifiable(offset_days)
    existing = notifications.map(&:message)
    possible - existing
  end

end
