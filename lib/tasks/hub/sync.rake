require 'hub-api'

namespace :hub do
  desc "Update local database with new/updated message streams from hub"
  task :sync => :environment do
    api_base = ENV['HUB_API_BASE']
    raise "HUB_API_BASE environment variable must be defined" unless api_base

    log_file, level = ENV['HUB_SYNC_AUDIT_LOG'].to_s.split(':')
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
      MESSAGE_ATTS = %w{name title language offset_days sms_text}
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
  end
end
