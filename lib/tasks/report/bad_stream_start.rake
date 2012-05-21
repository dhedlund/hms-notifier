require 'csv'

namespace :report do
  desc "enrollments where stream start is too early relative to date created"
  task :bad_stream_start, [:num_months] => :environment do |t,args|
    num_months = args[:num_months].to_i

    columns = [ :ext_user_id, :status, :phone_number, :stream_start, :created_at ]
    puts CSV.generate_line columns

    Enrollment.scoped.each do |enrollment|
      next unless enrollment.stream_start <= enrollment.created_at.to_date - num_months.months
      puts CSV.generate_line columns.map {|c| enrollment[c] }
    end
  end
end
