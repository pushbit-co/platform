require 'spec_helper.rb'

describe "github" do
  context "when unauthenticated" do
    it "should respond with error" do
      post '/webhooks/github'
      expect(last_response.status).to eql(403)
    end
  end

  context "when authenticated" do
    context "with ping event" do
      it "should respond with empty success" do
        header "X-Github-Event", "ping"
        post_with_gh_signature '/webhooks/github', { zen: true }.to_json
        expect(last_response.status).to eql(204)
      end
    end

    context "with pull_request event" do
      let(:event) { File.read('spec/fixtures/github/pull_request.json') }
      let!(:repo) { create(:repo, github_id: 35_129_377, github_full_name: "baxterthehacker/public-repo") }

      it "should respond with successful create" do
        t = double
        header "X-Github-Event", "pull_request"
        expect(Pushbit::Trigger).to receive(:create!).and_return(t)
        expect(t).to receive(:execute!).and_return(true)
        post_with_gh_signature '/webhooks/github', event
        expect(last_response.status).to eql(200)
      end
    end

    context "with pull_request event from ourselves" do
      let(:event) { JSON.parse File.read('spec/fixtures/github/pull_request.json') }

      it "should respond with empty success" do
        event['sender']['login'] = ENV.fetch('GITHUB_BOT_LOGIN')

        header "X-Github-Event", "pull_request"
        post_with_gh_signature '/webhooks/github', event.to_json
        expect(last_response.status).to eql(204)
        expect(Pushbit::CloneRepoWorker.jobs.length).to eql(0)
      end
    end
  end
end

describe "cron" do
  it "should add cron event worker job" do
    post '/webhooks/cron'
    expect(last_response.status).to eql(200)
    expect(Pushbit::CronEventWorker.jobs.length).to eql(1)
  end
end
