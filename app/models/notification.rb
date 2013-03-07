class Notification < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :message
  has_many :updates, :class_name => 'NotificationUpdate'
  has_many :responses, :class_name => 'NotificationResponse'

  after_initialize :default_values
  before_validation :prevent_reactivation
  before_save :generate_uuid, :unless => :uuid?

  NEW = 'NEW'
  TEMP_FAIL = 'TEMP_FAIL'
  PERM_FAIL = 'PERM_FAIL'
  DELIVERED = 'DELIVERED'
  CANCELLED = 'CANCELLED'
  ACTIVE_STATUSES = [ NEW, TEMP_FAIL ]
  INACTIVE_STATUSES = [ PERM_FAIL, DELIVERED, CANCELLED ]
  VALID_STATUSES = [ ACTIVE_STATUSES, INACTIVE_STATUSES ].flatten

  serialize :variables, Hash

  validates :uuid, :uniqueness => true
  validates :enrollment_id, :presence => true
  validates :message_id, :presence => true, :uniqueness => { :scope => :enrollment_id }
  validates :delivery_date, :presence => true
  validates :status, :inclusion => VALID_STATUSES

  scope :active, where(:status => ACTIVE_STATUSES)

  def default_values
    self.status ||= NEW
  end

  def delivery_date
    self[:delivery_date] ||= calc_delivery_date
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def cancelled?
    status == CANCELLED
  end

  def variables
    self[:variables] || {}
  end


  protected

  def calc_delivery_date
    self[:delivery_date] = nil
    if enrollment && message
      self[:delivery_date] = enrollment.stream_start + message.offset_days
    end
  end

  def generate_uuid
    write_attribute :uuid, SecureRandom.uuid
  end

  def prevent_reactivation
    return true unless changes[:status]

    before, after = changes[:status]
    if INACTIVE_STATUSES.include?(before) && ACTIVE_STATUSES.include?(after)
      # attempting to reactivate an inactive notification
      errors.add(:status, 'cannot change from inactive to active')
      false
    else
      true
    end
  end

end
