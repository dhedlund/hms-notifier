class Enrollment < ActiveRecord::Base
  belongs_to :message_stream
  has_many :notifications

  after_initialize :default_values
  before_validation :prevent_duplicate_enrollments
  before_save :cancel_all_notifications, :if => :cancelled?

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
  validates :message_stream_id, :presence => true

  scope :active, where(:status => ACTIVE)
  scope :completed, where(:status => COMPLETED)
  scope :cancelled, where(:status => CANCELLED)

  def default_values
    self.status ||= ACTIVE
  end

  def ready_messages
    return [] unless active?

    offset_days = (Date.today - stream_start).to_i
    possible = message_stream.messages.notifiable(offset_days)
    existing = notifications.map(&:message)
    possible - existing
  end

  def enqueue_ready_messages
    ready_messages.each { |m| notifications.create!(:message => m) }
  end

  def active?
    status == ACTIVE
  end

  def cancelled?
    status == CANCELLED
  end


  protected

  def prevent_duplicate_enrollments
    duplicates = Enrollment.where(
      :status => ACTIVE,
      :phone_number => phone_number,
      :message_stream_id => message_stream_id
    )
    duplicates = duplicates.where('id != ?', id) if id
    return true if duplicates.none?

    errors.add(:base, 'would create a duplicate active enrollment')
    false
  end

  def cancel_all_notifications
    active_notifications = notifications.active
    active_notifications.each do |notification|
      notification.update_attributes(:status => Notification::CANCELLED)
    end

    active_notifications.all?(&:cancelled?)
  end

end
