require 'open-uri'
require 'yaml'

module Pushbit
  class BehaviorSyncronizationWorker < BaseWorker

    def work
      Octokit.auto_paginate = true

      repos = Octokit.organization_repositories('pushbit-behaviors')
      repos.each do |data|
        begin
          # load configuration from yml file in root of repo
          config = YAML.load open("https://raw.githubusercontent.com/#{data.full_name}/master/config.yml").read
          
          if config.class == Hash
            Pushbit::Behavior.find_or_create_with(config)
          else
            logger.info "config.yml corrupt or invalid for #{data.full_name}"
          end
        rescue OpenURI::HTTPError => e
          if e.message.match('404')
            logger.info "config.yml missing for #{data.full_name}"
          else
            logger.info "Could not load config for #{data.full_name}"
          end
        end
      end
    end
  end
end