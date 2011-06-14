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
    notifications.select(&:active?).each do |notification|
      update = notification.updates.last.try(:clone) || NotificationUpdate.new
      update.changed_attributes.clear
      update.notification = notification

      if update.changed?
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
