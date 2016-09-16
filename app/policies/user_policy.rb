module Pushbit
  class UserPolicy < Policy
    def create?
      true
    end

    def read?
      #TODO
    end

    def update?
      user.id == record.id
    end

    def delete?
      false
    end
  end
end