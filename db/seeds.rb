Pushbit::Behavior.delete_all

Pushbit::Behavior.create!({
  kind: "issue_assigner",
  name: "Issue Assigner",
  image: "organization",
  description: "Assigns issues to a collaborator on the repository to make sure that someone is always responsible.",
  triggers: ["issue_opened"],
  tags: ["assign", "issue"],
  settings: {
    team: {
      type: "integer",
      label: "Restrict assignees to collaborators on a team",
      options: ["All"],
      default: ["All"]
    }
  }
})

Pushbit::Behavior.create!({
  kind: "issue_labeller",
  name: "Issue Labeller",
  image: "tag",
  description: "Automatically labels issues that are missing labels based on the title and body.",
  triggers: ["issue_opened", "issue_edited"],
  tags: ["label", "issue"],
  settings: {
    edit: {
      type: "boolean",
      label: "Allow labels to be added when an issue is edited",
      default: true
    },
    whitelist: {
      type: "string",
      multiple: true,
      label: "Allow these labels to be automatically added",
      options: ["bug", "enhancement", "feature", "question", "discussion", "help wanted"],
      default: ["bug", "enhancement", "feature", "question", "discussion", "help wanted"],
    }
  }
})

Pushbit::Behavior.create!({
  kind: "issue_welcomer",
  name: "Contributor Welcome",
  image: "comment",
  description: "Replies to issues created by non-collaborators with a custom welcome message.",
  triggers: ["issue_opened"],
  tags: ["comment", "issue", "collaborator"],
  settings: {
    comment: {
      type: "string",
      multiline: true,
      label: "What should the message say"
    }
  }
})
