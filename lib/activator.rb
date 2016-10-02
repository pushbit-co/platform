require 'securerandom'
require 'sshkey'

module Pushbit
  class Activator
    attr_reader :repo, :user, :client

    def initialize(repo, user)
      @repo = repo
      @user = user
      @client = user.client
    end

    def self.activate(repo, user)
      new(repo, user).activate
    end

    def self.deactivate(repo, user)
      new(repo, user).deactivate
    end

    def activate
      add_collaborator
      add_deploy_key
      add_webhook
      repo.activate!(user)
    end

    def deactivate
      remove_collaborator
      remove_deploy_key
      remove_webhook
      repo.deactivate!(user)
    end

    private

    # collaborator is used to create comments and issues
    def add_collaborator
      unless client.collaborator?(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
        client.add_collaborator(
          repo.github_full_name,
          ENV.fetch('GITHUB_BOT_LOGIN')
        )
      end
    end

    # deploy key is used to read / write code
    def add_deploy_key
      repo.ensure_salt

      # generate ssh-keypair
      key = SSHKey.generate(
        type:       'DSA',
        bits:       4096,
        comment:    'bot@pushbit.co',
        passphrase: repo.deploy_key_passphrase
      )

      # save public_key to github API
      deploy_key = client.add_deploy_key(repo.github_full_name, 'Pushbit', key.ssh_public_key)

      # save private_key to database
      repo.update_attributes(
        ssh_key: key.private_key,
        deploy_key_id: deploy_key.id
      )
    end

    def add_webhook
      repo.ensure_webhook_token

      hook = client.create_hook(
        repo.github_full_name,
        'web',
        {
          url: "#{ENV.fetch('APP_URL')}/webhooks/github",
          content_type: 'json',
          secret: repo.webhook_token
        },
        events: %w(push pull_request issues issue_comment commit_comment),
        active: true
      )
      repo.update_attribute(:webhook_id, hook.id)
    rescue Octokit::UnprocessableEntity
      # Hook already exists on this repository
      # TODO filter what we catch here a lil better
    end

    def remove_collaborator
      if client.collaborator?(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
        client.remove_collaborator(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
      end
    end

    def remove_deploy_key
      if repo.deploy_key_id
        client.remove_deploy_key(repo.github_full_name, repo.deploy_key_id)
        repo.update_attributes(
          deploy_key_id: nil,
          ssh_key: nil
        )
      end
    end

    def remove_webhook
      if repo.webhook_id
        client.remove_hook(repo.github_full_name, repo.webhook_id)
        repo.update_attributes(
          webhook_id: nil,
          webhook_token: nil
        )
      end
    end
  end
end
