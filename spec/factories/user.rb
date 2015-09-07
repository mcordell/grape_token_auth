FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "someperson#{n}@example.com" }
    uid { email }
    provider 'email'
    password 'secret'
    password_confirmation 'secret'

    trait :confirmed do
      confirmed_at Time.now
    end

    trait :unconfirmed do
      confirmed_at nil
    end
  end
end
