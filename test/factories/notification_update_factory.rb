Factory.define :notification_update do |f|
  f.action         'CREATE'

  f.association :notification
end
