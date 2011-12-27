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
  desc "Pull events from Google Calendar"
  task :pull => :environment do
    filename = Rails.root.join('config', 'clinic-cal.yml')
    config = YAML::load(ERB.new(filename.read).result)[Rails.env]
    config =  HashWithIndifferentAccess.new(config)

#   log_file, level = config[:log_file].to_s.split(':')
#   if log_file
#     logger = Logger.new(log_file)
#     logger.level = level ? Logger.const_get(level.upcase) : Rails.logger.level
#     logger.formatter = Logger::Formatter.new
#   else
#     logger = RAILS_DEFAULT_LOGGER
#   end

    active_enrollments = Hash[Enrollment.active.map { |e| [e.ext_user_id, e] }]

    service = GCal4Ruby::Service.new
    service.authenticate(config[:username], config[:password])

    config[:calendars].each do |cal_name|
      calendar = GCal4Ruby::Calendar.find(service, cal_name, :first).first

      events = calendar.events.select { |e| e.start_time > 7.days.ago }
      events.sort_by(&:start_time).each do |event|
        begin
          content = YAML.parse(event.content)

          first_name, last_name = event.title.match(/^([^ ]+)(?: (.*))?/)[1,2]
          appt_date = event.start_time.to_date
          language = config[:default_language]

          appt_formatters = Hash.new { |hash,date| date.strftime("%A, %d %b %Y") }
          appt_formatters['Chichewa'] = lambda do |date|
            date.strftime("#{DAY_CHICHEWA[date.wday]}, %d %b %Y")
          end

          phone_number = content['Cell Number'].try(:value).to_s.gsub(' ', '')
          phone_number.sub!(/^0/, '265')

          attributes = {
            :phone_number => phone_number,
            :first_name   => first_name,
            :last_name    => last_name,
            :variables    => {
              :name     => event.title,
              :location => event.where,
              :date     => appt_formatters[language].call(appt_date)
            },
          }

          if enrollment = active_enrollments.delete(event.id)
            enrollment.update_attributes!(attributes)
          else
            enrollment = Enrollment.create!(attributes.merge({
              :ext_user_id       => event.id,
              :stream_start      => (event.start_time - 7.days).to_date,
              :message_stream_id => MessageStream.find_by_name(config[:message_stream]).id,
              :delivery_method   => 'SMS',
              :language          => language,
            }))
          end

        rescue ActiveRecord::RecordInvalid => e
          warn e
        end
      end
    end

    # anything left was probably deleted from the calendar, cancel
    active_enrollments.values.each do |enrollment|
      enrollment.update_attributes(:status => Enrollment::CANCELLED)
    end
  end
end
