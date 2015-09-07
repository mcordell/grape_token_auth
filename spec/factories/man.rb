FactoryGirl.define do
  factory :man do
    sequence(:email) { |n| "someperson#{n}@example.com" }
    uid { email }
    provider 'email'
    password 'password'
    password_confirmation 'password'

    trait :confirmed do
      confirmed_at Time.now
    end

    trait :unconfirmed do
      confirmed_at nil
    end
  end
end
