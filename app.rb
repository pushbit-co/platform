STDOUT.sync = true

# for autoload paths
$LOAD_PATH << File.expand_path('../', __FILE__)

require "rack"
require "rack/contrib"
require "rack-flash"
require "secure_headers"
require "sinatra/base"
require "sinatra/json"
require "sinatra/asset_pipeline"
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
require_relative "app/policies"

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

      # settings for asset pipeline
      set :assets_precompile, %w(bundle.js app.scss *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2)
      set :assets_css_compressor, :sass
      set :assets_js_compressor, :uglifier
      set :assets_prefix, %w(assets app/assets)

      # trigger the app to sync with behaviors stored on github when
      # the application starts up
      BehaviorSyncronizationWorker.perform_async
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
    register Sinatra::AssetPipeline

    use Rack::Session::Cookie, key: 'session',
                               # secret: ENV.fetch("SESSION_SECRET"),
                               path: '/',
                               expire_after: 60 * 60 * 24 * 365,
                               httponly: true,
                               secure: ENV.fetch("RACK_ENV") != 'development'

    use Rack::Deflater
    use Rack::PostBodyContentTypeParser
    use Raven::Rack
    use Rack::Flash, accessorize: [:notice, :error, :param]
    use SecureHeaders::Middleware
    include WillPaginate::Sinatra::Helpers

    Raven.configure do |config|
      config.excluded_exceptions = ['Sinatra::NotFound']
    end

    SecureHeaders::Configuration.default do |config|
      config.hsts = "max-age=#{20.years.to_i}"
      config.x_frame_options = "DENY"
      config.x_content_type_options = "nosniff"
      config.x_xss_protection = "1; mode=block"
      config.x_download_options = "noopen"
      config.x_permitted_cross_domain_policies = "none"
      config.csp = {
        default_src: %w('self'),
        connect_src: %w(wws: 'self' checkout.stripe.com),
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

    before do
      check_csrf
      set_timezone
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
