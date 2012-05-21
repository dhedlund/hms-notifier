Enrollment.active.each do |enrollment|
  notification = enrollment.notifications.last
  last_in_stream = enrollment.message_stream.messages \
    .where(:language => enrollment.language) \
    .where("sms_text #{enrollment.delivery_method == 'SMS' ? 'IS NOT' : 'IS'} NULL") \
    .last

  if notification && notification.message == last_in_stream
    if Notification::INACTIVE_STATUSES.include?(notification.status)
      # notification is no longer active so it's technically completed
      enrollment.update_attributes(:status => Enrollment::COMPLETED)
    elsif notification.delivery_date.to_time < 2.weeks.ago
      # notification is stale and something got lost
      enrollment.update_attributes(:status => Enrollment::COMPLETED)
    end
  end

end
