FactoryGirl.define do
  factory :user, class: Pushbit::User do
    login { Faker::Internet.user_name }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    github_id { Faker::Number.number(6) }
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
    webhook_token { "thisisatoken" }
    salt { "thisisasalt" }
    ssh_key {
     "-----BEGIN DSA PRIVATE KEY-----
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
-----END DSA PRIVATE KEY-----
"
    }
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
    kind { 'bundle-update' }
    active { true }
    settings do
      {
        filter: {
          label: "Setting label",
          type: :string
        }
      }
    end
  end
end
