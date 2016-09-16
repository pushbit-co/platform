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

            # convert nested subobjects into individual underscored keys
            # eg: see repository and author fields in config
            config.clone.each do |key, value|
              next unless value.class == Hash
              separated = false
              value.each do |subkey, subvalue|
                column = "#{key}_#{subkey}"
                column_exists = Behavior.column_names.include?(column)
                if column_exists
                  config[column] = subvalue
                  separated = true
                end
              end

              if separated
                config.delete key
              end
            end

            Behavior.find_or_create_with(config)
          else
            logger.info "config.yml corrupt or invalid for #{data.full_name}"
          end
        rescue OpenURI::HTTPError => e
          if e.message.match('404')
            logger.info "config.yml missing for #{data.full_name}"
          else
            logger.info "config.yml could not be loaded for #{data.full_name}"
          end
        end
      end
    end
  end
end
