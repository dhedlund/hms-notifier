FactoryGirl.define do
  factory :enrollment do
    first_name 'First'
    sequence(:phone_number) { |n| "+01234-5678-#{n}" }
    delivery_method 'SMS'
    stream_start Date.today

    message_stream
  end
end
