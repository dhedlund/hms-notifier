require 'csv'

namespace :report do
  desc "CSV Monthly delivery report for enrollments and notifications"
  task :deliveries_by_month => :environment do |t,args|

    columns = [
      'Month', '', 'SMS Child', 'Voice Child', 'SMS Pregnancy', 'Voice Pregnancy',
      'All SMS', 'All Voice', 'All Child', 'All Pregnancy',
      'Grand Totals'
    ]

    # FIXME: truncate to start of month if within first week of the month?
    notifications = Notification.scoped

    notifications = notifications.where("status != 'NEW'") # a few notifications never attempted
    notifications_by_month = notifications.group_by {|n| n.delivery_date.beginning_of_month }
    months = notifications_by_month.keys.sort.reverse # newest to oldest

    #-----[ enrollments ]-------------------------------------------------------

    puts CSV.generate_line(['Enrollments with at least one notification in calendar month'])
    puts CSV.generate_line(columns)
    months.each do |month|
      notifications = notifications_by_month[month]
      enrollments = notifications.map(&:enrollment).uniq

      edata = {}
      enrollments.each do |enrollment|
        sname = enrollment.message_stream.name
        mname = enrollment.delivery_method

        edata[sname] ||= {}
        edata[sname][mname] ||= 0
        edata[sname]['All'] ||= 0
        edata['All'] ||= {}
        edata['All'][mname] ||= 0
        edata['All']['All'] ||= 0

        edata[sname][mname] += 1
        edata[sname]['All'] += 1
        edata['All'][mname] += 1
        edata['All']['All'] += 1
      end

      puts CSV.generate_line([
        month.strftime('%Y-%m'),
        'Current Enrollments',
        edata['child']['SMS'],
        edata['child']['IVR'],
        edata['pregnancy']['SMS'],
        edata['pregnancy']['IVR'],
        edata['All']['SMS'],
        edata['All']['IVR'],
        edata['child']['All'],
        edata['pregnancy']['All'],
        edata['All']['All'],
      ])

    end
    puts CSV.generate_line([])

    #-----[ notifications ]-----------------------------------------------------

    puts CSV.generate_line(['Notification Delivery'])
    puts CSV.generate_line(columns)

    csv_rows = {
      'Success' => lambda {|n| n.status == 'DELIVERED' },
      'Fails'   => lambda {|n| n.status != 'DELIVERED' },
      'Total'   => lambda {|n| true                    },
    }

    months.each do |month|
      notifications = notifications_by_month[month]

      ['Success', 'Fails', 'Total'].map { |k| [k, csv_rows[k]] }.each do |name,matcher|
        ndata = {}
        notifications.select(&matcher).each do |notification|
          sname = notification.message.message_stream.name
          mname = notification.enrollment.delivery_method

          ndata[sname] ||= {}
          ndata[sname][mname] ||= 0
          ndata[sname]['All'] ||= 0
          ndata['All'] ||= {}
          ndata['All'][mname] ||= 0
          ndata['All']['All'] ||= 0

          ndata[sname][mname] += 1
          ndata[sname]['All'] += 1
          ndata['All'][mname] += 1
          ndata['All']['All'] += 1
        end

        puts CSV.generate_line([
          month.strftime('%Y-%m'),
          name,
          ndata['child']['SMS'],
          ndata['child']['IVR'],
          ndata['pregnancy']['SMS'],
          ndata['pregnancy']['IVR'],
          ndata['All']['SMS'],
          ndata['All']['IVR'],
          ndata['child']['All'],
          ndata['pregnancy']['All'],
          ndata['All']['All'],
        ])
      end

    end
  end
end
