Factory.define :notification do |f|
  f.delivery_date Date.today

  f.association :enrollment
  f.association :message
end
