class NotificationResponse < ActiveRecord::Base
  belongs_to :notification

  validates :notification_id, :presence => true
  validates :status, :presence => true
end
