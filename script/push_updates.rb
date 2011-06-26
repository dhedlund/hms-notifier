#!/usr/bin/env ruby

require 'restclient'

api_base = ENV['HUB_API_BASE']
api_base ||= 'http://foo:bar@localhost:3000/api' if Rails.env.development?
raise "HUB_API_BASE environment variable must be defined" unless api_base

NotificationUpdate.pending.each do |u|
  json_data = {
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
  }.to_json

  response = RestClient.post("#{api_base}/notifications", json_data,
    :accept => :json, :content_type => :json)

  u.update_attributes(:uploaded_at => Time.now)
end
