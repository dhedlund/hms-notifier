Factory.define :enrollment do |f|
  f.first_name 'First'
  f.last_name 'Last'
  f.phone_number '+01234-5678-9'
  f.delivery_method 'SMS'
  f.stream_start Date.today

  f.association :message_stream
end
