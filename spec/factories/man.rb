FactoryGirl.define do
  factory :man do
    sequence(:email) { |n| "someperson#{n}@example.com" }
    uid { email }
    provider 'email'
    password 'password'
    password_confirmation 'password'

    trait :confirmed do
      # confirmable stub
    end
  end
end
