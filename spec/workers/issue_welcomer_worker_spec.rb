require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::IssueWelcomerWorker.new }
  let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_opened.json')) }
  let(:trigger) { create(:trigger, payload: payload) }

  context "with non collaborator" do
    it "adds a welcome comment" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/collaborators")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/collaborators_empty.json'), headers: { 'Content-Type' => 'application/json' })

      stub = stub_request(:post, "https://api.github.com/repos/baxterthehacker/public-repo/issues/2/comments")
        .to_return(:status => 200, :body => "", :headers => {})

      worker.perform(trigger.id, {'comment' => 'This is a comment'})
      expect(stub).to have_been_requested
    end
  end

  context "with collaborator" do
    it "does not add a welcome comment" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/collaborators")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/collaborators.json'), headers: { 'Content-Type' => 'application/json' })

      stub = stub_request(:post, "https://api.github.com/repos/baxterthehacker/public-repo/issues/2/comments")
        .to_return(:status => 200, :body => "", :headers => {})

      worker.perform(trigger.id, {'comment' => 'This is a comment'})
      expect(stub).to_not have_been_requested
    end
  end
end
