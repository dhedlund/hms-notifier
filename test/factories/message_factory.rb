Factory.define :message do |f|
  f.sequence(:name) { |n| "message#{n}" }
  f.title 'message title'
  f.offset_days 0
  f.sms_text 'whyamihere'

  f.association :message_stream
end
