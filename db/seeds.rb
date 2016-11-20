Pushbit::Behavior.delete_all

Pushbit::Behavior.create!({
  kind: "issue_assigner",
  name: "Issue Assigner",
  description: "Assigns issues to a collaborator",
  triggers: ["issue_opened"],
})

Pushbit::Behavior.create!({
  kind: "issue_labeller",
  name: "Issue Labeller",
  description: "Automatically adds common labels to issues",
  triggers: ["issue_opened"],
})
