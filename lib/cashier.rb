module Pushbit
  class Cashier
    attr_reader :repo, :user, :token

    def initialize(repo, user, token = nil)
      @repo = repo
      @user = user
      @token = token
    end

    def self.subscribe(repo, user, token = nil)
      new(repo, user, token).subscribe
    end

    def self.unsubscribe(repo, user)
      new(repo, user, nil).unsubscribe
    end

    def subscribe
      create_customer unless user.has_customer?
      create_subscription unless repo.subscription
      add_repo_to_subscription
    end

    def unsubscribe
      remove_repo_from_subscription
      subscription.destroy
    end

    def subscription
      @subscription ||= repo.subscription || create_subscription
    end

    private

    def current_repo_ids
      subscription.metadata.repo_ids.split(",")
    end

    def add_repo_to_subscription
      repo_ids = current_repo_ids + [repo.id.to_s]
      subscription.metadata.repo_ids = repo_ids.uniq.join(",")
      subscription.stripe_subscription.quantity = repo_ids.uniq.length
      subscription.save
    end

    def remove_repo_from_subscription
      repo_ids = current_repo_ids.reject { |id| id.to_s == repo.id.to_s }

      if repo_ids.empty?
        subscription.metadata.repo_ids = nil
        subscription.delete
      else
        subscription.metadata.repo_ids = repo_ids.join(",")
        subscription.stripe_subscription.quantity = repo_ids.length
        subscription.save
      end
    end

    def create_subscription
      Subscription.find_or_create_with(
        plan: 'private-monthly',
        repo: repo,
        user: user
      )
    end

    def create_customer
      customer = Stripe::Customer.create(
        email: user.email,
        metadata: { user_id: user.id },
        source: token
      )

      user.update_attribute(:stripe_customer_id, customer.id)
      customer
    end
  end
end