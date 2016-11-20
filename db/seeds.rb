Pushbit::Behavior.delete_all

Pushbit::Behavior.create!({
  kind: "issue_assigner",
  name: "Issue Assigner",
  description: "Assigns issues to a collaborator",
  triggers: ["issue_opened"],
})

Pushbit::Behavior.create!({
  kind: "pull_request_assigner",
  name: "Pull Request Assigner",
  description: "Assigns Pull Requests to a collaborator",
  triggers: ["pull_request_opened"],
})

Pushbit::Behavior.create!({
  kind: "issue_reminder",
  name: "Issue Reminder",
  description: "Reminds assignee that an issue is becoming stale",
  triggers: ["cron"],
})
