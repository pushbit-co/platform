Pushbit::Behavior.find_or_create_with(
  kind: 'unbox',
  name: 'Unbox',
  discovers: "setup problem",
  description: "This special behavior runs once when you connect a repository to check its setup and suggest improvements.",
  active: true,
  triggers: ['setup'],
  actions: ['message']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'mentioned',
  name: 'Mentioned',
  description: "Suggests who would be the best person to review a pull request based on previous commits.",
  discovers: "team mate",
  active: false,
  triggers: ['pull_request_opened'],
  actions: ['comment']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'bundler-audit',
  name: 'Bundler Audit',
  description: "Runs on every commit and ensures you're not falling prey to known security vulnerabilities.",
  discovers: "security vulnerabilty",
  tone: 'negative',
  active: true,
  tags: ['Ruby'],
  files: ['Gemfile', 'Gemfile.lock'],
  triggers: ['cron', 'pull_request_opened', 'task_completed_unbox'],
  actions: ['issue']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'bundler-update',
  name: 'Bundler Update',
  description: "Runs once a day to make sure your bundle is kept upto date with the latest releases.",
  discovers: "outdated dependency",
  tone: 'negative',
  active: true,
  tags: ['Ruby'],
  files: ['Gemfile', 'Gemfile.lock'],
  triggers: ['cron', 'task_completed_unbox'],
  actions: ['pull_request']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'filecop',
  name: 'Filecop',
  description: "Detects potentially hazardeous commited files such as keys, tokens and certs",
  discovers: "sensitive file",
  tone: 'negative',
  active: true,
  triggers: ['pull_request_opened'],
  actions: ['line_comment']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'rubocop',
  name: 'Rubocop',
  description: "Checks for and fixes your code when it steps out of your teams style guide.",
  discovers: "style violation",
  tone: 'negative',
  active: true,
  tags: ['Ruby'],
  files: ['.+\.rb\z'],
  triggers: ['pull_request_opened', 'task_completed_unbox'],
  actions: ['pull_request']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'brakeman',
  name: 'Brakeman',
  description: "Notifies you of known security vulnerabilities in pull requests.",
  discovers: "security vulnerability",
  tone: 'negative',
  active: true,
  tags: ['Ruby'],
  files: ['.+\.rb\z'],
  triggers: ['pull_request_opened', 'task_completed_unbox'],
  actions: ['line_comment', 'issue']
)

Pushbit::Behavior.find_or_create_with(
  kind: 'grammaro',
  name: 'Grammaro',
  description: "Looks at every commited text, html and markdown file, checking for likely grammar and spelling mistakes.",
  discovers: "spelling mistake",
  tone: 'negative',
  active: false,
  files: ['.+\.md\z', '.+\.txt\z'],
  triggers: ['pull_request_opened'],
  actions: ['line_comment']
)
