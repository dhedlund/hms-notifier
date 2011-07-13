module AdminHelper
  def primary_nav(selected=:dashboard)
    nav = [
      { :name => :dashboard,     :path => admin_path                   },
      { :name => :messages,      :path => admin_message_streams_path   },
      { :name => :enrollments,   :path => admin_enrollments_path       },
      { :name => :notifications, :path => admin_notifications_path     },
      { :name => :users,         :path => admin_users_path             },
    ]

    nav.each { |i| i[:title] ||= i[:name].to_s.titleize }
    nav.select { |i| i[:name] == selected }[0][:selected] = true
    nav
  end

  def nav_hierarchy(hierarchy)
    paths = Hash[primary_nav.map { |n| [n[:name], n[:path]] }]
    hierarchy.map do |node|
      case node
      when Symbol
        title = node.to_s.titleize
        paths[node] ? link_to(title, paths[node]) : title
      when MessageStream
        link_to("Stream: #{node.title}", [:admin, node])
      when Message
        link_to("Message: #{node.title}", [:admin, node.message_stream, node])
      when Enrollment
        link_to("Enrollment: #{node.id}", [:admin, node])
      when Notification
        link_to("Notification: #{node.id}", [:admin, node])
      when NotificationUpdate
        link_to("Update: #{node.id}", [:admin, node.notification, node])
      when NotificationResponse
        link_to("Response: #{node.id}", [:admin, node.notification, node])
      when User
        link_to("User: #{node.username}", [:admin, node])
      else
        node
      end
    end
  end
end
