class NotificationUpdate < ActiveRecord::Base
  belongs_to :notification

  CREATE = 'CREATE'
  UPDATE = 'UPDATE'
  CANCEL = 'CANCEL'
  VALID_ACTIONS = [ CREATE, UPDATE, CANCEL ]

  validates :notification_id, :presence => true
  validates :action, :inclusion => VALID_ACTIONS
  validates :first_name, :presence => true
  validates :phone_number, :presence => true
  validates :delivery_method, :presence => true
  validates :message_path, :presence => true
  validates :delivery_date, :presence => true

  alias_method :orig_notification=, :notification=
  def notification=(value)
    self.orig_notification=(value)
    self.cache_notification_data
  end


  protected

  def cache_notification_data
    self.delivery_date = notification.try(:delivery_date)
    self.preferred_time = notification.try(:preferred_time)

    enrollment = notification.try(:enrollment)
    self.first_name = enrollment.try(:first_name)
    self.phone_number = enrollment.try(:phone_number)
    self.delivery_method = enrollment.try(:delivery_method)

    message = notification.try(:message)
    self.message_path = message.try(:path)
  end

end