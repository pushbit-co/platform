module Pushbit
  class App < Sinatra::Base
    not_found do
      status 404

      if request.xhr?
        json ok: false, error: "The endpoint you requested does not exist."
      else
        erb :'errors/404'
      end
    end

    # error Pushbit::AuthenticationError do
    #  status 401
    #  json :ok => false, :error => "This endpoint requires authentication - make sure your authorization token is in the request headers."
    # end

    # error Pushbit::AuthorizationError do
    #  status 403
    #  json :ok => false, :error => "You are not authorized to access this resource."
    # end

    error Stripe::InvalidRequestError do
      status 422

      if request.xhr?
        json ok: false, error: env['sinatra.error'].message
      else
        flash[:error] = env['sinatra.error'].message
        back
      end
    end

    error Octokit::Unauthorized do
      status 403

      if request.xhr?
        json ok: false, error: "The endpoint you requested was not authorized."
      else
        warden.logout
      end
    end

    error ActiveRecord::RecordInvalid do
      status 422
      json ok: false, error: env['sinatra.error'].message
    end

    error ActiveRecord::RecordNotFound do
      status 404

      if request.xhr?
        json ok: false, error: "The resource you requested does not exist. Perhaps it was recently deleted."
      else
        erb :'errors/404'
      end
    end

    error do
      status 500

      if request.xhr?
        json ok: false, error: "An unexpected error occurred, we've been alerted about the issue. Perhaps try the request again?"
      else
        erb :'errors/500'
      end
    end
  end
end