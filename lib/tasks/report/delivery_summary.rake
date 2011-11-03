require 'csv'

namespace :report do
  desc "CSV Monthly delivery report for enrollments and notifications"
  task :delivery_summary, [:month] => :environment do |t,args|
    unless args[:month] =~ /^\d{4}-\d{2}$/
      raise "invalid date: #{args[:month]} (YYYY-MM format required)"
    end

    range_start = Date.parse("#{args[:month]}-01")
    range_end = range_start + 1.month

    columns = [
      'SMS Child', 'Voice Child', 'SMS Pregnancy', 'Voice Pregnancy',
      'All SMS', 'All Voice', 'All Child', 'All Pregnancy',
      'Grand Totals'
    ]
    puts CSV.generate_line([nil, *columns])

    notifications = Notification.where('delivery_date BETWEEN ? AND ?', range_start, range_end)
    notifications = notifications.where("status != 'NEW'") # a few notifications never attempted
    enrollments = notifications.map(&:enrollment).uniq

    #-----[ enrollments ]-------------------------------------------------------

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

    puts CSV.generate_line(['(enrollments w/ at least one notification in calendar month)'])


    #-----[ notifications ]-----------------------------------------------------

    puts CSV.generate_line(['Notification Delivery'])

    csv_rows = {
      'Success' => "status = 'DELIVERED'",
      'Fails' => "status != 'DELIVERED'",
      'Total' => "1 = 1",
    }

    ['Success', 'Fails', 'Total'].map { |k| [k, csv_rows[k]] }.each do |name,sql|
      ndata = {}
      notifications.where(sql).each do |notification|
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
