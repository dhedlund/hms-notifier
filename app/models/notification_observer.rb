class NotificationObserver < ActiveRecord::Observer
  observe :enrollment, :notification

  def after_create(o)
    record_update(o, NotificationUpdate::CREATE)
  end

  def after_update(o)
    record_update(o, NotificationUpdate::UPDATE)
  end

  def record_update(o, action)
    notifications = o.respond_to?(:notifications) ? o.notifications.reload : [o]
    notifications.select { |n| n.active? || n.cancelled? }.each do |notification|
      action = NotificationUpdate::CANCEL if notification.cancelled?

      update = notification.updates.last.try(:clone) || NotificationUpdate.new
      next if update.action == NotificationUpdate::CANCEL

      update.changed_attributes.clear
      update.notification = notification

      if update.changed? || notification.cancelled?
        update.action = action
        notification.updates << update
      end
    end

    # called notifications() if an Enrollment, which isn't obvious in the model.
    # this caches association results and plays havoc if new notification aren't
    # directly added to the enrollment, reset to prevent insanity
    notifications.reset if notifications.respond_to?(:reset)
  end

end
