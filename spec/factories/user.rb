FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "someperson#{n}@example.com" }
    uid { email }
    provider 'email'
  end
end
