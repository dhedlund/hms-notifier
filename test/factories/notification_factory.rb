FactoryGirl.define do
  factory :notification do
    association :enrollment
    association :message
  end
end
