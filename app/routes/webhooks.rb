module Pushbit
  class App < Sinatra::Base
    post "/webhooks/github" do
      if processable?
        payload = params
        repo = Repo.find_by!(github_id: payload["repository"]["id"])
        logger.info repo.inspect

        verify_signature!(repo.webhook_token)

        trigger = Trigger.create!(
          kind: github_event,
          payload: payload,
          repo: repo,
          triggered_by: payload['sender']['id']
        )
        trigger.execute!

        status 200
      else
        status 204
      end
    end

    private

    def processable?
      return false unless %w(pull_request_opened issue_opened issue_edited).include? github_event
      return false if params['sender']['login'] == ENV.fetch('GITHUB_BOT_LOGIN')
      true
    end

    def github_event
      if params['action']
        event = env['HTTP_X_GITHUB_EVENT']

        # convert to singular as github API is inconsistent here
        event = 'issue' if event == 'issues'
        "#{event}_#{params['action']}"
      else
        env['HTTP_X_GITHUB_EVENT']
      end
    end

    def github_event_id
      env['HTTP_X_GITHUB_DELIVERY']
    end

    def verify_signature!(token)
      request.body.rewind
      payload_body = request.body.read
      allowed = env['HTTP_X_HUB_SIGNATURE'] && Security.verify_github_signature(payload_body, env['HTTP_X_HUB_SIGNATURE'], token)

      return halt 403, "Signatures didn't match!" unless allowed
    end
  end
end
