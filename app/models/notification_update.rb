class NotificationUpdate < ActiveRecord::Base
  belongs_to :notification

  CREATE = 'CREATE'
  UPDATE = 'UPDATE'
  CANCEL = 'CANCEL'
  VALID_ACTIONS = [ CREATE, UPDATE, CANCEL ]

  serialize :variables, Hash

  validates :notification_id, :presence => true
  validates :action, :inclusion => VALID_ACTIONS
  validates :first_name, :presence => true
  validates :phone_number, :presence => true
  validates :delivery_method, :presence => true
  validates :message_path, :presence => true
  validates :delivery_date, :presence => true

  scope :pending, where(:uploaded_at => nil)

  alias_method :orig_notification=, :notification=
  def notification=(value)
    self.orig_notification=(value)
    self.cache_notification_data
  end

  def variables
    self[:variables] || {}
  end


  protected

  def cache_notification_data
    self.delivery_date = notification.try(:delivery_date)

    enrollment = notification.try(:enrollment)
    self.first_name = enrollment.try(:first_name)
    self.phone_number = enrollment.try(:phone_number)
    self.preferred_time = enrollment.try(:preferred_time)
    self.delivery_method = enrollment.try(:delivery_method)
    self.ext_user_id = enrollment.try(:ext_user_id)
    self.variables = enrollment.try(:variables)

    message = notification.try(:message)
    self.message_path = message.try(:path)

    if expire_days = message.try(:expire_days)
      self.delivery_expires = self.delivery_date + expire_days.days
    end

    self.action = CANCEL if notification.try(:status) == Notification::CANCELLED
  end

end
