require_relative './policies/policy'

module Pushbit
  autoload :RepoPolicy, "app/policies/repo_policy"
  autoload :UserPolicy, "app/policies/user_policy"
end
