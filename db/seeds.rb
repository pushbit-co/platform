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
  description: "Automatically adds common labels to issues where possible based on the title and body of the issue.",
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
