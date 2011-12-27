require 'gcal4ruby'

DAY_CHICHEWA = [
  '',          # Sunday
  'Lolemba',   # Monday
  'Lachiwiri', # Tuesday
  'Lachitatu', # Wednesday
  'Lachinayi', # Thursday
  'Lachisanu', # Friday
  '',          # Saturday
]

namespace :gcal do
  desc "Display events from Google Calendar"
  task :display => :environment do
    filename = Rails.root.join('config', 'clinic-cal.yml')
    config = YAML::load(ERB.new(filename.read).result)[Rails.env]
    config =  HashWithIndifferentAccess.new(config)

    service = GCal4Ruby::Service.new
    service.authenticate(config[:username], config[:password])

    config[:calendars].each do |cal_name|
      calendar = GCal4Ruby::Calendar.find(service, cal_name, :first).first

      events = calendar.events.select { |e| e.start_time > 0.days.ago }
      events.sort_by(&:start_time).each do |event|
        content = YAML.parse(event.content)

        first_name, last_name = event.title.match(/^([^ ]+)(?: (.*))?/)[1,2]
        appt_date = event.start_time.to_date
        language = config[:default_language]

        appt_formatters = Hash.new { |hash,date| date.strftime("%A, %d %b %Y") }
        appt_formatters['Chichewa'] = lambda do |date|
          date.strftime("#{DAY_CHICHEWA[date.wday]}, %d %b %Y")
        end

        attributes = {
          :phone_number => content['Cell Number'].try(:value),
          :first_name   => first_name,
          :last_name    => last_name,
          :variables    => {
            :name     => event.title,
            :location => event.where,
            :date     => appt_formatters[language].call(appt_date)
          },
        }

        puts attributes.to_yaml
      end
    end

  end
end
