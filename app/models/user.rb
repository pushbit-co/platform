module Pushbit
  class User < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity
    include BCrypt

    attr_accessible :email, :login, :name, :onboarding_skipped
    before_create :set_beta
    after_create :create_action, :send_welcome_email

    has_many :memberships, dependent: :destroy
    has_many :repos, through: :memberships
    has_many :subscriptions

    validates :github_id, presence: true, uniqueness: true
    validates :login, presence: true, uniqueness: true

    def self.find_or_create_with(attributes)
      user = find_by(github_id: attributes[:github_id]) || User.new
      user.assign_attributes attributes, without_protection: true

      # clear existing repo memberships whenever our token scope changes
      if user.token_scopes_changed?
        user.last_synchronized_at = nil
        user.repos.clear unless user.has_access_to_private_repos?
      end

      user.save!
      user
    end

    def first_name
      name.split(' ').first if name
    end

    def active_repos
      repos.active
    end

    def has_customer?
      !!stripe_customer_id
    end

    def customer
      if has_customer?
        @customer ||= Stripe::Customer.retrieve(stripe_customer_id)
      end
    end

    def token=(value)
      unless value == token
        encrypted_token = Security.encrypt(value)
        write_attribute(:token, encrypted_token)
      end
    end

    def token
      encrypted_token = read_attribute(:token)
      Security.decrypt(encrypted_token) unless encrypted_token.nil?
    end

    def has_active_repos?
      active_repos.count > 0
    end

    def has_access_to_private_repos?
      if token_scopes
        token_scopes.split(",").include? "repo"
      else
        false
      end
    end

    def sync_repositories!
      if !syncing? && (!last_synchronized_at || last_synchronized_at < 2.minutes.ago)
        update_attribute(:syncing, true)
        RepoSyncronizationWorker.perform_async(id)
      end
    end

    def client
      @client ||= Octokit::Client.new(access_token: token)
    end

    private

    def create_action
      Action.create!({
                       kind: 'signedup',
                       user: self,
                       github_id: github_id
                     }, without_protection: true)
    end

    def send_welcome_email
      EmailWorker.perform_async(:signedup, id)
    end

    def set_beta
      self.beta = true if %w(awsmsrc tommoor).include?(login)
    end
  end
end