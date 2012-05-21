require 'csv'

namespace :report do
  desc "enrollments with a high number of failures"
  task :failures, [:fail_pct,:status] => :environment do |t,args|
    threshold_pct = args[:fail_pct].to_f / 100.0
    statuses = args[:status] ? [args[:status]] : Enrollment::VALID_STATUSES

    STATUS_LEGEND = {
      Notification::NEW       => '.',
      Notification::DELIVERED => '*',
      Notification::TEMP_FAIL => 'x',
      Notification::PERM_FAIL => 'X',
      Notification::CANCELLED => '-',
    }

    puts 'Legend:'
    puts '  ACTIVE  current enrollment status'
    puts '  [...]   list of notifications w/ status, one char per notification'
    puts '  |       30-day boundary, notifications to right within last 30 days'
    puts '  (#)     # of failures in a row w/o a successful delivery since'
    puts
    puts 'Notification Statuses:'
    puts Notification::VALID_STATUSES.map {|s| "  #{STATUS_LEGEND[s]}  #{s}" }
    puts

    Enrollment.where(:status => statuses).each do |enrollment|
      notifications = enrollment.notifications
      total = notifications.where(:status => Notification::INACTIVE_STATUSES).count
      failed = notifications.where(:status => Notification::PERM_FAIL).count
      fail_pct = total > 0 ? failed / total.to_f : 0
      next unless fail_pct >= threshold_pct

      older = notifications.where('delivery_date < ?', 30.days.ago)
      newer = notifications.where('delivery_date > ?', 30.days.ago)
      print '%5s ' % enrollment.id
      print "#{enrollment.ext_user_id} #{enrollment.delivery_method} "
      print '%9s [ ' % enrollment.status
      print older.map {|n| STATUS_LEGEND[n.status] }
      print ' | '
      print newer.map {|n| STATUS_LEGEND[n.status] }
      print ' ]'

      tail_fails = notifications.where(:status => Notification::INACTIVE_STATUSES).reverse \
        .take_while {|n| n.status == Notification::PERM_FAIL}
      print " (#{tail_fails.length})"      
      puts
    end
  end
end
