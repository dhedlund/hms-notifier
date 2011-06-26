#!/usr/bin/env ruby

require 'restclient'

api_base = ENV['HUB_API_BASE']
api_base ||= 'http://foo:bar@localhost:3000/api' if Rails.env.development?
raise "HUB_API_BASE environment variable must be defined" unless api_base

# FIXME: Figure out why we need to load another model before trying to load Enrollment
# or Notification. This appears to be related to the use of observers against the
# Enrollment and Notification models.
NotificationObserver

status_url = "#{api_base}/notifications/updated?only_status=1"
json = RestClient.get status_url, :accept => :json
data = ActiveSupport::JSON.decode json

data.map {|v| v['notification']}.compact.each do |nr|
  notification = Notification.find_by_uuid(nr['uuid']) or next
  notification.responses.create!(
    :status       => nr['status'],
    :delivered_at => nr['delivered_at'],
    :error_type   => nr['error'] ? n['error']['type'] : nil,
    :error_msg    => nr['error'] ? n['error']['message'] : nil
  )
end
