Factory.define :notification_response do |f|
  f.status 'DELIVERED'

  f.association :notification
end
