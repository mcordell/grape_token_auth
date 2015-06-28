FactoryGirl.define do
  factory :man do
    sequence(:email) { |n| "someperson#{n}@example.com" }
    uid { email }
    provider 'email'
  end
end
