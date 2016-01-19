module Pushbit
  class BaseWorker
    include Sidekiq::Worker
    
    def perform(*args)
      Raven.capture do
        work(*args)
      end
    end
    
    private
    
    def client
      @client ||= Octokit::Client.new(:access_token => ENV.fetch("GITHUB_TOKEN"))
    end
  end
end
