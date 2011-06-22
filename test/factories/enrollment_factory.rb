Factory.define :enrollment do |f|
  f.first_name 'First'
  f.last_name 'Last'
  f.sequence(:phone_number) { |n| "+01234-5678-#{n}" }
  f.delivery_method 'SMS'
  f.stream_start Date.today

  f.association :message_stream
end
