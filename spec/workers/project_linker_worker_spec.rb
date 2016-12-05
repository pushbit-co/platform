require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::ProjectLinkerWorker.new }
  let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_opened.json')) }
  let(:trigger) { create(:trigger, payload: payload) }

  context "with no project" do
    it "does nothing"
  end

  context "with a project" do
    it "does nothing without matching label" do
      stub_request(:get, "https://api.github.com/projects/123/columns")
        .to_return(:status => 200, :body => File.read('spec/fixtures/github/webmock/columns.json'), :headers => { 'Content-Type' => 'application/json' })

      worker.perform(trigger.id, {
        'projects' => [
          {'id' => 123, 'labels' => ['desktop']}
        ]
      })
    end

    it "adds issue to project with matching label" do
      stub_request(:get, "https://api.github.com/projects/123/columns")
        .to_return(:status => 200, :body => File.read('spec/fixtures/github/webmock/columns.json'), :headers => { 'Content-Type' => 'application/json' })

      stub = stub_request(:post, "https://api.github.com/projects/columns/367/cards")
        .with(:body => "{\"content_type\":\"Issue\",\"content_id\":#{payload['issue']['id']}}")
        .to_return(:status => 200, :body => "", :headers => {})

      worker.perform(trigger.id, {
        'projects' => [
          {'id' => 123, 'labels' => ['bug']}
        ]
      })
      expect(stub).to have_been_requested
    end
  end
end
