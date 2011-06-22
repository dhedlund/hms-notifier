#!/usr/bin/env ruby

# FIXME: Figure out why we need to load another model before trying to load Enrollment
# or Notification. This appears to be related to the use of observers against the
# Enrollment and Notification models.
NotificationObserver

Enrollment.active.each { |e| e.enqueue_ready_messages }
