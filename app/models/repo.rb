require 'sshkey'

module Pushbit
  class Repo < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    has_many :tasks
    has_many :triggers
    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    has_many :repo_behaviors, dependent: :destroy
    has_many :behaviors, through: :repo_behaviors
    has_one :subscription
    belongs_to :owner

    def self.active
      where(active: true)
    end

    def self.private
      where(private: true)
    end

    def self.find_or_create_with(attributes, owner_attributes)
      repo = find_by(github_id: attributes[:github_id]) || Repo.new
      repo.owner = Owner.find_or_create_with(owner_attributes) unless repo.owner_id

      # merges tags with any existing on the repo
      repo.tags = attributes[:tags] | repo.tags if attributes[:tags]
      attributes.delete(:tags)

      repo.assign_attributes(attributes, without_protection: true)
      repo.save!
      repo
    end

    def public?
      !private?
    end

    def inactive?
      !active?
    end

    def name
      github_full_name.split('/').last if github_full_name
    end

    def github_owner
      github_full_name.split('/').first if github_full_name
    end

    def stripe_subscription_id
      subscription.stripe_subscription_id if subscription
    end

    def labels
      Octokit.auto_paginate = true
      client = Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))
      client.labels(github_full_name)
    end

    def ensure_salt
      self.update_attributes!(salt: SecureRandom.hex) unless salt
    end

    def ensure_webhook_key
      self.update_attributes!(webhook_key: SecureRandom.hex) unless webhook_key
    end

    def deploy_key_passphrase
      Digest::SHA256.hexdigest("#{ENV.fetch('DEPLOY_KEYS_PASSWORD')}#{salt}")
    end

    def unencrypted_ssh_key
      key = SSHKey.new(ssh_key)
      key.passphrase = deploy_key_passphrase
      key.private_key
    end

    def activate!(user)
      self.update_attributes!(
        active: true,
        behaviors: Behavior.all
      )

      trigger = Trigger.create!(
        kind: 'setup',
        repo: self,
        triggered_by: user.github_id
      )
      trigger.execute!

      Action.create!({
         kind: 'subscribe',
         repo: self,
         user: user,
         github_id: github_id
       }, without_protection: true)
    end

    def deactivate!(user)
      update(active: false, behaviors: [])

      Action.create!(
        kind: 'unsubscribe',
        repo: self,
        user: user,
        github_id: github_id
      )
    end
  end
end
