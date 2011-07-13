#!/usr/bin/env ruby

require 'hub-api'

# USAGE:
#   [ENV_VARS]... rails runner script/sync_message_streams.rb
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
logger.info 'syncing message streams...'
data = hub.get '/streams'

begin
  # TODO: deactivate any streams or messages no longer on hub (req. :deleted_at)
  STREAM_ATTS = %w{name title}
  MESSAGE_ATTS = %w{name title offset_days sms_text}
  data.map {|v| v['message_stream']}.compact.each do |s|
    unless stream = MessageStream.find_by_name(s['name'])
      logger.info "creating message stream '#{s['name']}'..."
      stream = MessageStream.new
    end
    stream.attributes = Hash[STREAM_ATTS.map {|k| [k,s[k]] }]
    if stream.changed?
      logger.debug "MESSAGE STREAM: #{stream.attributes.inspect}"
      logger.error "ERRORS: #{stream.errors.inspect}" if stream.invalid?
      stream.save!
    end

    s['messages'].map {|v| v['message']}.compact.each do |m|
      unless message = stream.messages.find_by_name(m['name'])
        logger.info "creating message '#{m['name']} for stream '#{s['name']}'..."
        message = stream.messages.build
      end
      message.attributes = Hash[MESSAGE_ATTS.map {|k| [k,m[k]] }]
      if message.changed?
        logger.debug "MESSAGE: #{message.attributes.inspect}"
        logger.error "ERRORS: #{message.errors.inspect}" if message.invalid?
        message.save!
      end
    end
  end

rescue => e
  logger.error e
  raise
end
