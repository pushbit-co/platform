require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::IssueLabellerWorker.new }
  let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_opened.json')) }
  let(:trigger) { create(:trigger, payload: payload) }
  let(:payload_edited) { JSON.parse(File.read('spec/fixtures/github/issue_edited.json')) }
  let(:trigger_edited) { create(:trigger, payload: payload_edited) }

  context "with an existing label" do
    it "does not apply any new labels" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/labels")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/labels.json'), headers: { 'Content-Type' => 'application/json' })
      worker.perform(trigger.id)
    end
  end

  context "with no matching repo labels" do
    it "does not apply any new labels" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/labels")
          .to_return(status: 200, body: "[]", headers: { 'Content-Type' => 'application/json' })
      worker.perform(trigger.id)
    end
  end

  context "without any existing labels" do
    let(:trigger) do
      payload['issue']['labels'] = []
      create(:trigger, payload: payload)
    end

    it "applys a label" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/labels")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/labels.json'), headers: { 'Content-Type' => 'application/json' })
      stub = stub_request(:post, "https://api.github.com/repos/baxterthehacker/public-repo/issues/2/labels")
          .with(:body => "[\"enhancement\"]")

      worker.perform(trigger.id)
      expect(stub).to have_been_requested
    end

    it "does not apply a label with non-matching whitelist" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/labels")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/labels.json'), headers: { 'Content-Type' => 'application/json' })
      stub = stub_request(:post, "https://api.github.com/repos/baxterthehacker/public-repo/issues/2/labels")
          .with(:body => "[\"enhancement\"]")

      worker.perform(trigger.id, {
        'whitelist' => ['bug']
      })
      expect(stub).to_not have_been_requested
    end

    it "does not apply a label with non-matching edited" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/labels")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/labels.json'), headers: { 'Content-Type' => 'application/json' })
      stub = stub_request(:post, "https://api.github.com/repos/baxterthehacker/public-repo/issues/2/labels")
          .with(:body => "[\"enhancement\"]")

      worker.perform(trigger_edited.id, {
        'edit' => false
      })
      expect(stub).to_not have_been_requested
    end

  end
end
