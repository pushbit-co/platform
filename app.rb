STDOUT.sync = true

# for autoload paths
$LOAD_PATH << File.expand_path('../', __FILE__)

require "rack"
require "rack/contrib"
require "rack-flash"
require "secure_headers"
require "sinatra/base"
require "sinatra/json"
require "sinatra/assetpack"
require "sentry-raven"
require "bcrypt"
require "warden"
require "warden/github"
require "docker"
require "less"
require "sidekiq"
require "stripe"
require "will_paginate"
require "will_paginate/active_record"

require_relative "lib/security.rb"
require_relative "lib/cashier.rb"
require_relative "lib/activator.rb"
require_relative "lib/mailer.rb"
require_relative "lib/mailer_error"
require_relative "lib/authorization_error"
require_relative "lib/authentication_error"

require_relative "app/helpers/auth_helpers"
require_relative "app/helpers/view_helpers"
require_relative "app/helpers/date_helpers"

require_relative "app/presenters/action_presenter"

require_relative "app/models"
require_relative "app/routes"
require_relative "app/workers"

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
WillPaginate.per_page = 20

module Pushbit
  class App < Sinatra::Base
    configure do
      set :root, File.dirname(__FILE__)
      set :bind, '0.0.0.0'
      set :logging, true
      set :json_encoder, :to_json
      set :show_exceptions, false
      set :raise_errors, false
      set :method_override, true
      set :views, 'app/views'
      set :erb, :layout_options => { :views => 'app/views/layouts' }

      register Sinatra::AssetPack
    end

    Warden::Strategies.add(:basic) do
      def valid?
        !!env['HTTP_AUTHORIZATION']
      end

      def auth
        @auth ||= Rack::Auth::Basic::Request.new(env)
      end

      def store?
        false
      end

      def expected_token
        Digest::MD5.hexdigest "#{ENV.fetch('BASIC_AUTH_SECRET')}#{params['task_id']}"
      end

      def authenticate!
        fail!("Authentication method not found") unless auth.provided?
        fail!("Authentication not found") unless auth.basic?
        fail!("Authentication failed") unless expected_token == auth.credentials.first

        success!(auth)
      end
    end

    helpers AuthHelpers
    helpers ViewHelpers
    helpers DateHelpers

    use Rack::Session::Cookie, key: 'session',
                               secret: ENV.fetch("SESSION_SECRET"),
                               path: '/',
                               expire_after: 60 * 60 * 24 * 365,
                               httponly: true,
                               secure: ENV.fetch("RACK_ENV") != 'development'
    use Rack::Deflater
    use Rack::PostBodyContentTypeParser
    use Raven::Rack
    Raven.configure do |config|
      config.excluded_exceptions = ['Sinatra::NotFound']
    end
    use Rack::Flash, accessorize: [:notice, :error, :param]
    use SecureHeaders::Middleware
    include WillPaginate::Sinatra::Helpers

    SecureHeaders::Configuration.default do |config|
      config.hsts = "max-age=#{20.years.to_i}"
      config.x_frame_options = "DENY"
      config.x_content_type_options = "nosniff"
      config.x_xss_protection = "1; mode=block"
      config.x_download_options = "noopen"
      config.x_permitted_cross_domain_policies = "none"
      config.csp = {
        default_src: %w('self'),
        connect_src: %w(wws: 'self'),
        frame_src: %w(checkout.stripe.com),
        img_src: %w(avatars.githubusercontent.com www.google-analytics.com avatars2.githubusercontent.com q.stripe.com avatars.githubusercontent.com 'self'),
        script_src: %w('unsafe-inline' www.google-analytics.com checkout.stripe.com code.jquery.com maxcdn.bootstrapcdn.com 'self'),
        font_src: %w(fonts.gstatic.com maxcdn.bootstrapcdn.com 'self'),
        style_src: %w(checkout.stripe.com fonts.googleapis.com maxcdn.bootstrapcdn.com 'self'),
        block_all_mixed_content: true
      }
    end

    use Warden::Manager do |config|
      config.failure_app = self
      config.default_strategies :basic, :github
      config.scope_defaults :default, config: {
        scope: 'user:email,public_repo',
        action: 'auth/unauthenticated'
      }
      config.scope_defaults :private, config: {
        scope: 'user:email,repo',
        action: 'auth/unauthenticated'
      }
      config.serialize_from_session { |key| Warden::GitHub::Verifier.load(key) }
      config.serialize_into_session { |user| Warden::GitHub::Verifier.dump(user) }
    end

    assets do
      serve '/js',     from: 'app/assets/js'
      serve '/css',    from: 'app/assets/css'
      serve '/images', from: 'app/assets/images'

      # Add all the paths that Less should look in for @import'ed files
      Less.paths << File.join(App.root, 'app/assets/css')

      css :app, 'css/app.css', ['/css/app.css']
      css_compression :less

      js :app, 'js/app.js', ['/js/libs/jstz.min.js', '/js/app.js']
      js_compression :jsmin
    end

    before do
      check_csrf
      set_timezone
    end

    get '/' do
      if current_user
        if !current_user.beta?
          redirect '/beta'
        elsif current_user.has_active_repos?
          @repos = current_user.repos.active
          erb :dashboard
        else
          @repos = current_user.repos.active
          @pull_requests_opened = Trigger.where(kind: 'pull_request_opened', repo_id: @repos.pluck(:id))
          @pull_requests_merged = Action.where(github_status: 'merged', kind: 'pull_request', repo_id: @repos.pluck(:id))

          if !current_user.onboarding_skipped && (@repos.count < 1 || @pull_requests_opened.count < 1 || @pull_requests_merged.count < 1)
            erb :onboarding
          else
            @tasks = Task.paginate(page: params['page']).where(repo_id: current_user.repos.pluck(:id)).includes(:repo)
            @actions = Action.paginate(page: params['page']).for_user(current_user).includes(:task, :user)
            erb :dashboard
          end
        end
      else
        erb :home
      end
    end

    get '/beta' do
      erb :beta
    end

    get '/account' do
      authenticate!

      erb :account
    end

    get '/pricing' do
      erb :pricing
    end

    get '/security' do
      erb :security
    end

    get '/behaviors' do
      @behaviors = Behavior.all
      erb :behaviors
    end

    get '/subscribe' do
      authenticate!

      current_user.sync_repositories!

      if current_user.has_access_to_private_repos?
        @organizations = current_user.client.organizations
      else
        @organizations = []
      end

      flash[:notice] = "Note: During the beta Pushbit works best with projects written in Ruby, other languages coming soon!"
      erb :subscribe
    end

    private

    def set_timezone
      Time.zone = request.cookies['timezone']
    end

    def check_csrf
      session[:csrf] ||= SecureRandom.hex(32)

      response.set_cookie 'authenticity_token', {
        value: session[:csrf],
        expires: Time.now + (60 * 60 * 24 * 180),
        path: '/',
        httponly: true,
        secure: ENV.fetch("RACK_ENV") != "development"
      }

      # this is a Rack method, that basically asks
      # if we're doing anything other than GET
      unless request.safe?
        if session[:csrf] == params['_csrf'] && session[:csrf] == request.cookies['authenticity_token']
          # everything is good.
        elsif current_user
          # TODO, checking current_user here probably introduces a small hole
          halt 403, 'CSRF failed'
        end
      end
    end
  end
end
