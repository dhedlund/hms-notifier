require 'hub-api'

namespace :hub do
  desc "Push new notifications and notification updates to hub"
  task :push => :environment do
    # FIXME: Figure out why we need to load another model before trying to load Enrollment
    # or Notification. This appears to be related to the use of observers against the
    # Enrollment and Notification models.
    NotificationObserver

    api_base = ENV['HUB_API_BASE']
    raise "HUB_API_BASE environment variable must be defined" unless api_base

    log_file, level = ENV['HUB_PUSH_AUDIT_LOG'].to_s.split(':')
    if log_file
      logger = Logger.new(log_file)
      logger.level = level ? Logger.const_get(level.upcase) : Rails.logger.level
      logger.formatter = Logger::Formatter.new
    else
      logger = RAILS_DEFAULT_LOGGER
    end

    Enrollment.active.each { |e| e.enqueue_ready_messages }

    hub = HubAPI.new(api_base, :logger => logger)
    logger.info 'pushing notification updates to hub...'

    NotificationUpdate.pending.each do |u|
      begin
        logger.info "pushing notification update #{u.id}..."
        data = {
          'notification' => {
            'uuid'             => u.notification.uuid,
            'first_name'       => u.first_name,
            'phone_number'     => u.phone_number,
            'message_path'     => u.message_path,
            'delivery_method'  => u.delivery_method,
            'delivery_date'    => u.delivery_date.strftime('%Y-%m-%d'),
            'delivery_expires' => u.delivery_expires.try(:strftime, '%Y-%m-%d'),
            'preferred_time'   => u.preferred_time,
          }
        }
      rescue => e
        logger.error e
        raise
      end

      response = hub.post('/notifications', data)

      begin
        u.update_attributes(:uploaded_at => Time.now)
      rescue
        logger.error e
        raise
      end
    end
  end
end
