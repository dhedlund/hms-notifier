FactoryGirl.define do
  factory :notification_response do
    status 'DELIVERED'

    notification
  end
end
