require 'csv'

namespace :report do
  desc "enrollments with a high number of failures"
  task :failing_csv, [:fail_pct,:status] => :environment do |t,args|
    threshold_pct = args[:fail_pct].to_f / 100.0
    statuses = args[:status] ? [args[:status]] : Enrollment::VALID_STATUSES

    STATUS_LEGEND = {
      Notification::NEW       => '.',
      Notification::DELIVERED => '*',
      Notification::TEMP_FAIL => 'x',
      Notification::PERM_FAIL => 'X',
      Notification::CANCELLED => '-',
    }

#    puts 'Legend:'
#    puts '  ACTIVE  current enrollment status'
#    puts '  [...]   list of notifications w/ status, one char per notification'
#    puts '  |       30-day boundary, notifications to right within last 30 days'
#    puts '  (#)     # of failures in a row w/o a successful delivery since'
#    puts
#    puts 'Notification Statuses:'
#    puts Notification::VALID_STATUSES.map {|s| "  #{STATUS_LEGEND[s]}  #{s}" }
#    puts

    columns = [ 'First name', 'Last name','Phone number','Phone number length',
	'Language','Id','External user id', 
	'Status', 'Delivery method', 'Message stream','Old status','New status',
	'Older notifications count','Older new count','Older delivered count',
	'Older temp fail count','Older perm fail count','Older cancelled count',
	'Newer notifications count','Newer new count','Newer delivered count',
	'Newer temp fail count','Newer perm fail count','Newer cancelled count',
	'Total delivered percent','Tail fails' ]
    puts CSV.generate_line([ *columns ])
    Enrollment.where(:status => statuses).each do |enrollment|
      notifications = enrollment.notifications
      total = notifications.where(:status => Notification::INACTIVE_STATUSES).count
      failed = notifications.where(:status => Notification::PERM_FAIL).count
      fail_pct = total > 0 ? failed / total.to_f : 0
      next unless fail_pct >= threshold_pct

      older = notifications.where('delivery_date < ?', 30.days.ago)
      newer = notifications.where('delivery_date > ?', 30.days.ago)
      first_name = enrollment.first_name
      last_name = enrollment.last_name
      phone_number = enrollment.phone_number
      phone_number_length = phone_number.length
      language = enrollment.language
      id = enrollment.id
      extid = "#{enrollment.ext_user_id}"
      delivery_method =  "#{enrollment.delivery_method}"
      stat =  enrollment.status
      stream = enrollment.message_stream.name
      old = older.map {|n| STATUS_LEGEND[n.status] }
      new = newer.map {|n| STATUS_LEGEND[n.status] }
      older_notifications_count = older.count
      older_new_count = older.where(:status => 'NEW').count
      older_delivered_count = older.where(:status => 'DELIVERED').count
      older_temp_fail_count = older.where(:status => 'TEMP_FAIL').count
      older_perm_fail_count = older.where(:status => 'PERM_FAIL').count
      older_cancelled_count = older.where(:status => 'CANCELLED').count
      newer_notifications_count = newer.count
      newer_new_count = newer.where(:status => 'NEW').count
      newer_delivered_count = newer.where(:status => 'DELIVERED').count
      newer_temp_fail_count = newer.where(:status => 'TEMP_FAIL').count
      newer_perm_fail_count = newer.where(:status => 'PERM_FAIL').count
      newer_cancelled_count = newer.where(:status => 'CANCELLED').count
      total_notifications = notifications.count
      total_delivered = notifications.where(:status => 'DELIVERED').count
      total_delivered_percent = (total_notifications > 0) ? ((total_delivered.to_f / total_notifications.to_f) * 100.0 ) : 0
      total_delivered_percent_formatted = '%.2f' % total_delivered_percent
      tail_fails = notifications.where(:status => Notification::INACTIVE_STATUSES).reverse \
        .take_while {|n| n.status == Notification::PERM_FAIL}
      tail = "#{tail_fails.length}"      
      puts CSV.generate_line([first_name,last_name,phone_number,phone_number_length,
	language,id,extid,stat,delivery_method,stream,old,new,
	older_notifications_count,older_new_count,older_delivered_count,
	older_temp_fail_count,older_perm_fail_count,older_cancelled_count,
	newer_notifications_count,newer_new_count,newer_delivered_count,
	newer_temp_fail_count,newer_perm_fail_count,newer_cancelled_count,
	total_delivered_percent_formatted,tail])
    end
  end
end
