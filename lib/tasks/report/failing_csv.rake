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

    all_columns = [
	'total_notifications',
	'total_delivered_percent',
	'first_name',
	'last_name',
	'phone_number',
	'phone_number_length',
	'language',
	'id',
	'extid',
	'stat',
	'delivery_method',
	'stream',
	'old',
	'new',
	'older_notifications_count',
	'older_new_count',
	'older_delivered_count',
	'older_temp_fail_count',
	'older_perm_fail_count',
	'older_cancelled_count',
	'newer_notifications_count',
	'newer_new_count',
	'newer_delivered_count',
	'newer_temp_fail_count',
	'newer_perm_fail_count',
	'newer_cancelled_count',
#	'total_delivered_percent',
	'tail_fails']


    column_names = { 'first_name' => 'First name',
	 'last_name' => 'Last name',
	'phone_number' => 'Phone number',
	'phone_number_length' =>'Phone number length',
	'language' => 'Language',
	'id' => 'Id',
	'extid' => 'External user id', 
	'stat' => 'Status', 
	'delivery_method' => 'Delivery method', 
	'stream' => 'Message stream',
	'old' => 'Old status',
	'new' => 'New status',
	'older_notifications_count' => 'Older notifications count',
	'older_new_count' => 'Older new count',
	'older_delivered_count' => 'Older delivered count',
	'older_temp_fail_count' => 'Older temp fail count',
	'older_perm_fail_count' => 'Older perm fail count',
	'older_cancelled_count' => 'Older cancelled count',
	'newer_notifications_count' => 'Newer notifications count',
	'newer_new_count' => 'Newer new count',
	'newer_delivered_count' => 'Newer delivered count',
	'newer_temp_fail_count' => 'Newer temp fail count',
	'newer_perm_fail_count' => 'Newer perm fail count',
	'newer_cancelled_count' => 'Newer cancelled count',
	'total_notifications' => 'Messages Attempted',
	'total_delivered_percent' => 'Total delivered percent',
	'tail_fails' => 'Tail fails' }

    column_title_list = [ 'First name', 'Last name','Phone number','Phone number length',
	'Language','Id','External user id', 
	'Status', 'Delivery method', 'Message stream','Old status','New status',
	'Older notifications count','Older new count','Older delivered count',
	'Older temp fail count','Older perm fail count','Older cancelled count',
	'Newer notifications count','Newer new count','Newer delivered count',
	'Newer temp fail count','Newer perm fail count','Newer cancelled count',
	'Total delivered percent','Tail fails' ]

    display_columns = 
{ 'first_name' => 1,
	 'last_name' => 1,
	'phone_number' => 1,
	'phone_number_length' => 1,
	'language' => 1,
	'id' => 1,
	'extid' => 1,
	'stat' => 1,
	'delivery_method' => 1,
	'stream' => 1,
	'old' => 0,
	'new' => 0,
	'older_notifications_count' => 1,
	'older_new_count' => 1,
	'older_delivered_count' => 1,
	'older_temp_fail_count' => 0,
	'older_perm_fail_count' => 1,
	'older_cancelled_count' => 0,
	'newer_notifications_count' => 1,
	'newer_new_count' => 1,
	'newer_delivered_count' => 1,
	'newer_temp_fail_count' => 0,
	'newer_perm_fail_count' => 1,
	'newer_cancelled_count' => 0,
	'total_notifications' => 1,
	'total_delivered_percent' => 1,
	'tail_fails' => 1,
}

titles = Array.new()
all_columns.each{ |key|
	if display_columns[key] == 1 
		titles << column_names[key] 
	end
}
    puts CSV.generate_line([ *titles ])
    Enrollment.where(:status => statuses).each do |enrollment|
      columns = Hash.new()
      notifications = enrollment.notifications
      columns["notifications"] = notifications
      total = notifications.where(:status => Notification::INACTIVE_STATUSES).count
      columns["total"] = total
      failed = notifications.where(:status => Notification::PERM_FAIL).count
      columns["failed"] = failed
      fail_pct = total > 0 ? failed / total.to_f : 0
      columns["fail_pct"] = fail_pct
      next unless fail_pct >= threshold_pct

      older = notifications.where('delivery_date < ?', 30.days.ago)
      newer = notifications.where('delivery_date > ?', 30.days.ago)
      first_name = enrollment.first_name
      columns['first_name'] = first_name
      last_name = enrollment.last_name
      columns['last_name'] = last_name
      phone_number = enrollment.phone_number
      columns['phone_number'] = phone_number
      phone_number_length = phone_number.length
      columns['phone_number_length'] = phone_number_length
      language = enrollment.language
      columns['language'] = language
      id = enrollment.id
      columns['id'] = id
      extid = "#{enrollment.ext_user_id}"
      columns['extid'] = extid
      delivery_method =  "#{enrollment.delivery_method}"
      columns['delivery_method'] = delivery_method
      stat =  enrollment.status
      columns['stat'] = stat
      stream = enrollment.message_stream.name
      columns['stream'] = stream
      old = older.map {|n| STATUS_LEGEND[n.status] }
      columns['old'] = old
      new = newer.map {|n| STATUS_LEGEND[n.status] }
      columns['new'] = new
      older_notifications_count = older.count
      columns['older_notifications_count'] = older_notifications_count
      older_new_count = older.where(:status => 'NEW').count
      columns['older_new_count'] = older_new_count
      older_delivered_count = older.where(:status => 'DELIVERED').count
      columns['older_delivered_count'] = older_delivered_count
      older_temp_fail_count = older.where(:status => 'TEMP_FAIL').count
      columns['older_temp_fail_count'] = older_temp_fail_count
      older_perm_fail_count = older.where(:status => 'PERM_FAIL').count
      columns['older_perm_fail_count'] = older_perm_fail_count
      older_cancelled_count = older.where(:status => 'CANCELLED').count
      columns['older_cancelled_count'] = older_cancelled_count
      newer_notifications_count = newer.count
      columns['newer_notifications_count'] = newer_notifications_count
      newer_new_count = newer.where(:status => 'NEW').count
      columns['newer_new_count'] = newer_new_count
      newer_delivered_count = newer.where(:status => 'DELIVERED').count
      columns['newer_delivered_count'] = newer_delivered_count
      newer_temp_fail_count = newer.where(:status => 'TEMP_FAIL').count
      columns['newer_temp_fail_count'] = newer_temp_fail_count
      newer_perm_fail_count = newer.where(:status => 'PERM_FAIL').count
      columns['newer_perm_fail_count'] = newer_perm_fail_count
      newer_cancelled_count = newer.where(:status => 'CANCELLED').count
      columns['newer_cancelled_count'] = newer_cancelled_count
      total_notifications = notifications.count
      columns['total_notifications'] = total_notifications
      total_delivered = notifications.where(:status => 'DELIVERED').count
      columns['total_delivered'] = total_delivered
      total_delivered_percent = (total_notifications > 0) ? ((total_delivered.to_f / total_notifications.to_f) * 100.0 ) : 0
      total_delivered_percent_formatted = '%.2f' % total_delivered_percent
      columns["total_delivered_percent"] = total_delivered_percent_formatted
      tail_fails = notifications.where(:status => Notification::INACTIVE_STATUSES).reverse \
        .take_while {|n| n.status == Notification::PERM_FAIL}
      #columns['tail_fails'] = tail_fails
      tail = "#{tail_fails.length}"
      columns["tail_fails"] = tail

   data_row = Array.new()
all_columns.each{ |key|
	if display_columns[key] == 1 
		data_row << columns[key] 
   #             puts columns[key]
	end
}
puts CSV.generate_line([ *data_row ])
#      puts CSV.generate_line([first_name,last_name,phone_number,phone_number_length,
#	language,id,extid,stat,delivery_method,stream,old,new,
#	older_notifications_count,older_new_count,older_delivered_count,
#	older_temp_fail_count,older_perm_fail_count,older_cancelled_count,
#	newer_notifications_count,newer_new_count,newer_delivered_count,
#	newer_temp_fail_count,newer_perm_fail_count,newer_cancelled_count,
#	total_delivered_percent_formatted,tail])
    end
  end
end
