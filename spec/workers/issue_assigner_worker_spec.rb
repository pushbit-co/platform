require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::IssueAssignerWorker.new }
  let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_opened.json')) }
  let(:trigger) { create(:trigger, payload: payload) }

  context "with no assignee" do
    it "assigns a random collaborator" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/collaborators")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/collaborators.json'), headers: { 'Content-Type' => 'application/json' })
      stub = stub_request(:patch, "https://api.github.com/repos/baxterthehacker/public-repo/issues/2")
          .to_return(:status => 200, :body => "", :headers => {})

      worker.perform(trigger.id)
      expect(stub).to have_been_requested
    end
  end

  context "with existing assignee" do
    let(:trigger) do
      payload['issue']['assignee'] = {id: 1, login: 'baxterthehacker'}
      create(:trigger, payload: payload)
    end

    it "does not reassign" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/collaborators")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/collaborators.json'), headers: { 'Content-Type' => 'application/json' })
      worker.perform(trigger.id)
    end
  end
end
