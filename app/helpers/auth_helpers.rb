module Pushbit
  module AuthHelpers

    def authenticated?
      warden.authenticated? || warden.authenticated?(:private)
    end

    def authenticate!
      unless authenticated?
        warden.authenticate!
      end
    end

    def warden
      env['warden']
    end

    def warden_user
      warden.authenticated?(:private) ? warden.user(:private) : warden.user
    end

    def current_user
      if authenticated?
        if warden_user.respond_to?(:api)
          @user ||= find_or_create_user
        end
      end
    end
    
    def authorize!(action, record, user=current_user)
      record_class = (record.class.name == "Class" ? record.to_s : record.class.name) + "Policy"
      class_path = "../policies/#{record_class.underscore.gsub("pushbit/","")}"
      
      require_relative class_path
      policy_class = Object.const_get(record_class)
      
      unless policy_class.new(user || current_user, record).send(:"#{action}?")
        raise Pushbit::AuthorizationError.new("Unauthorized Error")
      end
    end

    private

    def find_or_create_user
      primary = warden_user.api.emails.find {|s| s.primary }
      
      User.find_or_create_with({
        token: warden_user.api.access_token,
        token_scopes: warden_user.api.scopes.join(','),
        github_id: warden_user.id,
        gravatar_id: warden_user.gravatar_id,
        avatar_url: warden_user.avatar_url,
        email: primary.email || warden_user.email,
        name: warden_user.name,
        login: warden_user.login,
        company: warden_user.company
      })
    end
  end
end