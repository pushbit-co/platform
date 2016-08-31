# for autoload paths
$LOAD_PATH << File.expand_path('../', __FILE__)

require "sidekiq"
require "redis"
require "docker"
require "sentry-raven"
require "octokit"
require "bcrypt"
require "pony"

require_relative "lib/mailer"
require_relative "lib/security"
require_relative "lib/mailer_error"
require_relative "app/models"
require_relative "app/workers"

require_relative "app/helpers/view_helpers"

Pony.options = {
  from: 'help@pushbit.co',
  via: :smtp,
  via_options: {
    address: ENV.fetch('SMTP_HOST'),
    port: '587',
    domain: ENV.fetch('SMTP_DOMAIN'),
    user_name: ENV.fetch('SMTP_USERNAME'),
    password: ENV.fetch('SMTP_PASSWORD'),
    authentication: :plain,
    enable_starttls_auto: true
  }
}

#Docker.authenticate!({
#                       'username' => ENV.fetch("DOCKER_USERNAME"),
#                       'password' => ENV.fetch("DOCKER_PASSWORD"),
#                       'email' => ENV.fetch("DOCKER_EMAIL")
#                     })
#
#Docker.options[:read_timeout] = 3600

unless %w(test ci).include? ENV["RACK_ENV"]
  $redis = Redis.new(url: ENV.fetch('REDIS_URL'))
end
