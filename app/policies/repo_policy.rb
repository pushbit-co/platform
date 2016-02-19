module Pushbit
  class RepoPolicy < Policy
    def create?
      false
    end

    def read?
      record.public? || user.repos.include?(record)
    end

    def update?
      user.repos.include?(record) && record.active?
    end

    def delete?
      false
    end

    def subscribe?
      user.repos.include?(record) && record.inactive?
    end

    def unsubscribe?
      update?
    end

    def trigger?
      update?
    end
  end
end