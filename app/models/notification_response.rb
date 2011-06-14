class NotificationResponse < ActiveRecord::Base
  belongs_to :notification

  after_save :update_notification

  validates :notification_id, :presence => true
  validates :status, :presence => true


  protected

  def update_notification
    return true if status == notification.status

    notification.status = status
    notification.delivered_at = delivered_at

    unless notification.save
      notification.reload
      false
    end
  end
end
