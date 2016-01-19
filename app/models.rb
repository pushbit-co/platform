require "sinatra/activerecord"
require "protected_attributes"
require "sequential"

ActiveRecord::Base.logger = Logger.new(STDOUT)

module Pushbit
  autoload :Behavior, "app/models/behavior"
  autoload :DockerEvent, "app/models/docker_event"
  autoload :Owner, "app/models/owner"
  autoload :User, "app/models/user"
  autoload :Subscription, "app/models/subscription"
  autoload :Membership, "app/models/membership"
  autoload :RepoBehavior, "app/models/repo_behavior"
  autoload :Trigger, "app/models/trigger"
  autoload :Action, "app/models/action"
  autoload :Discovery, "app/models/discovery"
  autoload :Task, "app/models/task"
  autoload :Repo, "app/models/repo"
  autoload :Payload, "app/models/payload"
  autoload :Line, "app/models/line"
  autoload :Patch, "app/models/patch"
  autoload :LineComment, "app/models/line_comment"
end
