#!/usr/bin/env ruby

require 'restclient'

api_base = ENV['HUB_API_BASE']
api_base ||= 'http://foo:bar@localhost:3000/api' if Rails.env.development?
raise "HUB_API_BASE environment variable must be defined" unless api_base

# NOTE: use something along the following when we care about handling errors
#logger = Rails.logger
#RestClient.log = logger
#begin
#  json = RestClient.get "#{api_base}/streams", :accept => :json
#rescue RestClient::Exception => e # hub returned response but not successful
#rescue Errno::ETIMEDOUT => e # no connection to hub or hub not responding
#rescue => e # something else (i.e. connection refused, bad hostname, etc)
#end

json = RestClient.get "#{api_base}/streams", :accept => :json

# TODO: deactivate any streams or messages no longer on hub (req. :deleted_at)
STREAM_ATTS = %w{name title}
MESSAGE_ATTS = %w{name title offset_days}
data = ActiveSupport::JSON.decode json
data.map {|v| v['message_stream']}.compact.each do |s|
  stream = MessageStream.find_by_name(s['name']) || MessageStream.new
  stream.attributes = Hash[STREAM_ATTS.map {|k| [k,s[k]] }]
  stream.save! if stream.changed?

  s['messages'].each do |m|
    message = stream.messages.find_by_name(m['name']) || stream.messages.build
    message.attributes = Hash[MESSAGE_ATTS.map {|k| [k,m[k]] }]
    message.save! if message.changed?
  end
end
