#!/usr/bin/env ruby

require 'hub-api'

# USAGE:
#   [ENV_VARS]... rails runner script/push_updates.rb
#
# ENV VARS:
#   HUB_API_BASE=uri             URL to base of HUB API
#   LOG_FILE=log_file[:level]    log to file (i.e. LOG_FILE=streams.log:WARN)

api_base = ENV['HUB_API_BASE']
api_base ||= 'http://foo:bar@localhost:3000/api' if Rails.env.development?
raise "HUB_API_BASE environment variable must be defined" unless api_base

log_file, level = ENV['LOG_FILE'].to_s.split(':')
if log_file
  logger = Logger.new(log_file)
  logger.level = level ? Logger.const_get(level.upcase) : Rails.logger.level
  logger.formatter = Logger::Formatter.new
else
  logger = RAILS_DEFAULT_LOGGER
end


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
