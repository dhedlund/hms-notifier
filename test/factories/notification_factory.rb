Factory.define :notification do |f|
  f.association :enrollment
  f.association :message
end
