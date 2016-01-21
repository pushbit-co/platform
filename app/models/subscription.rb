module Pushbit
  class Subscription < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :stripe_subscription

    belongs_to :user
    belongs_to :repo

    delegate(
      :id,
      :metadata,
      :save,
      :delete,
      :quantity,
      :discount,
      to: :stripe_subscription
    )

    def self.find_or_create_with(plan:, repo:, user:)
      stripe_sub = user.customer.subscriptions.all.find { |subscription| subscription.plan.id == plan }
      stripe_sub = user.customer.subscriptions.create(plan: plan, metadata: { repo_ids: repo.id.to_s }) unless stripe_sub

      Subscription.create!({
                             user: user,
                             repo: repo,
                             stripe_subscription: stripe_sub,
                             stripe_subscription_id: stripe_sub.id
                           }, without_protection: true)
    end

    def stripe_subscription
      @stripe_subscription ||= user.customer.subscriptions.retrieve(stripe_subscription_id)
    end
  end
end