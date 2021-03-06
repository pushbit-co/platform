require 'spec_helper.rb'

describe "github" do
  context "when unauthenticated" do
    it "should respond with error" do
      post '/webhooks/github'
      expect(last_response.status).to eql(204)
    end
  end

  context "when authenticated" do
    let!(:repo) { create(:repo, github_id: 35_129_377, github_full_name: "baxterthehacker/public-repo") }

    context "with ping event" do
      it "should respond with empty success" do
        header "X-Github-Event", "ping"
        expect(Pushbit::Trigger).to_not receive(:create!)
        post_with_gh_signature '/webhooks/github', repo, { zen: true }.to_json
        expect(last_response.status).to eql(204)
      end
    end

    context "with pull_request event" do
      let(:event) { File.read('spec/fixtures/github/pull_request.json') }

      it "should respond with successful create" do
        t = double
        header "X-Github-Event", "pull_request"
        expect(Pushbit::Trigger).to receive(:create!).and_return(t)
        expect(t).to receive(:execute!).and_return(true)
        post_with_gh_signature '/webhooks/github', repo, event
        expect(last_response.status).to eql(200)
      end
    end

    context "with pull_request event created by pushbit" do
      let(:event) { JSON.parse File.read('spec/fixtures/github/pull_request.json') }

      it "should respond with empty success" do
        event['sender']['login'] = ENV.fetch('GITHUB_BOT_LOGIN')

        header "X-Github-Event", "pull_request"
        expect(Pushbit::Trigger).to_not receive(:create!)
        post_with_gh_signature '/webhooks/github', repo, event.to_json
        expect(last_response.status).to eql(204)
      end
    end
  end
end
