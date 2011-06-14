class Enrollment < ActiveRecord::Base
  belongs_to :message_stream
  has_many :notifications

  after_initialize :default_values

  ACTIVE = 'ACTIVE'
  COMPLETED = 'COMPLETED'
  CANCELLED = 'CANCELLED'
  VALID_STATUSES = [ ACTIVE, COMPLETED, CANCELLED ]

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :phone_number, :presence => true
  validates :delivery_method, :presence => true
  validates :stream_start, :presence => true
  validates :status, :inclusion => VALID_STATUSES

  def default_values
    self.status ||= ACTIVE
  end

  def ready_messages
    offset_days = (Date.today - stream_start).to_i
    possible = message_stream.messages.notifiable(offset_days)
    existing = notifications.map(&:message)
    possible - existing
  end

  def active?
    status == ACTIVE
  end

  def cancelled?
    status == CANCELLED
  end

end
