module Pushbit
  autoload :BaseWorker,                   "app/workers/base_worker"
  autoload :RepoSyncronizationWorker,     "app/workers/repo_syncronization_worker"
  autoload :CronEventWorker,              "app/workers/cron_event_worker"
  autoload :EmailWorker,                  "app/workers/email_worker"
  autoload :TriggerWorker,                "app/workers/trigger_worker"
  autoload :IssueAssignerWorker,          "app/workers/issue_assigner_worker"
  autoload :IssueLabellerWorker,          "app/workers/issue_labeller_worker"
end
