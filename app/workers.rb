module Pushbit
  autoload :BaseWorker,                   "app/workers/base_worker"
  autoload :BehaviorSyncronizationWorker, "app/workers/behavior_syncronization_worker"
  autoload :CronEventWorker,              "app/workers/cron_event_worker"
  autoload :EmailWorker,                  "app/workers/email_worker"
  autoload :ManualEventWorker,            "app/workers/manual_event_worker"
  autoload :RepoSyncronizationWorker,     "app/workers/repo_syncronization_worker"
  autoload :TriggerWorker,                "app/workers/trigger_worker"
end
