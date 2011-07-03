#!/usr/bin/env ruby

require 'hub-api'

# USAGE:
#   [ENV_VARS]... rails runner script/pull_responses.rb
#
# ENV VARS:
#   HUB_API_BASE=uri             URL to base of HUB API
#   LOG_FILE=log_file[:level]    log to file (i.e. LOG_FILE=streams.log:WARN)

# FIXME: Figure out why we need to load another model before trying to load Enrollment
# or Notification. This appears to be related to the use of observers against the
# Enrollment and Notification models.
NotificationObserver

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
logger.info 'pulling notification responses from hub...'
data = hub.get '/notifications/updated?only_status=1'

begin
  data.map {|v| v['notification']}.compact.each do |nr|
    logger.info "applying response to notification '#{nr['uuid']}'..."
    unless notification = Notification.find_by_uuid(nr['uuid'])
      logger.error "could not apply response for notification " +
        "'#{nr['uuid']}': notification not found"
      next
    end
    response = notification.responses.build(
      :status       => nr['status'],
      :delivered_at => nr['delivered_at'],
      :error_type   => nr['error'] ? n['error']['type'] : nil,
      :error_msg    => nr['error'] ? n['error']['message'] : nil
    )
    logger.debug "NOTIFICATION RESPONSE: #{response.attributes.inspect}"
    logger.error "ERRORS: #{response.errors.inspect}" if response.invalid?
    response.save!
  end

rescue => e
  logger.error e
  raise
end
