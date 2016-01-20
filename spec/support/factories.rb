FactoryGirl.define do
  factory :user, class: Pushbit::User do
    login { Faker::Internet.user_name }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    github_id { 123 }
  end

  factory :trigger, class: Pushbit::Trigger do
    kind { :manual }
    factory :cron_trigger do
      kind { :cron }
    end
    factory :github_push_trigger do
      kind { :push }
    end
    factory :github_pull_request_opened_trigger do
      kind { :pull_request_opened }
    end
    factory :github_pull_request_closed_trigger do
      kind { :pull_request_closed }
    end
    factory :github_issue_closed_trigger do
      kind { :issue_closed }
    end
    payload do
      {
        number: Faker::Number.number(3),
        pull_request: {
          head: {
            sha: SecureRandom.hex
          }
        }
      }
    end
    repo
  end

  factory :repo, class: Pushbit::Repo do
    active { true }
    github_id { Faker::Number.number(5) }
    github_full_name { "#{Faker::Lorem.word}/#{Faker::Lorem.word}" }
  end

  factory :task, class: Pushbit::Task do
    repo
    trigger
    behavior
    number { Faker::Number.number(3) }
  end

  factory :action, class: Pushbit::Action do
    repo
    task
    kind { :pull_request }
  end

  factory :behavior, class: Pushbit::Behavior do
    tone { 'negative' }
    active { true }
    discovers { 'style issue' }
  end
end
