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
      add_webhook
      repo.activate!(user)
    end

    def deactivate
      remove_collaborator
      remove_webhook
      repo.deactivate!(user)
    end

    private

    def add_collaborator
      unless client.collaborator?(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
        client.add_collaborator(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
      end
    end

    def add_webhook
      hook = client.create_hook(
        repo.github_full_name,
        'web',
        {
          url: "#{ENV.fetch('APP_URL')}/webhooks/github",
          content_type: 'json',
          secret: ENV.fetch('GITHUB_WEBHOOK_TOKEN')
        },
        events: %w(push pull_request issues issue_comment commit_comment),
        active: true
      )
      repo.update_attribute(:webhook_id, hook.id)
    rescue Octokit::UnprocessableEntity => e
      # Hook already exists on this repository
      # TODO filter what we catch here a lil better
    end

    def remove_collaborator
      if client.collaborator?(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
        client.remove_collaborator(repo.github_full_name, ENV.fetch('GITHUB_BOT_LOGIN'))
      end
    end

    def remove_webhook
      if repo.webhook_id
        client.remove_hook(repo.github_full_name, repo.webhook_id)
        repo.update_attribute(:webhook_id, nil)
      end
    end
  end
end