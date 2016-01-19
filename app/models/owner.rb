module Pushbit
  class Owner < ActiveRecord::Base
    has_many :repos

    def self.find_or_create_with(attributes)
      owner = find_by(github_id: attributes[:github_id]) || Owner.new
      owner.update!(attributes, without_protection: true)
      owner
    end
  end
end